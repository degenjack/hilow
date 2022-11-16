// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PayableContract.sol";
import "./CardsHoldingInterface.sol";

contract Hilow is VRFConsumerBaseV2, PayableHilowContract, Ownable {
    struct Card {
        uint256 value;
    }

    struct GameCards {
        Card firstDraw;
        Card secondDraw;
        Card thirdDraw;
    }

    struct Game {
        GameCards cards;
        uint256 betAmount;
        bool firstPrediction;
        bool secondPrediction;
    }
    address public AutomationAddress;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address constant vrfCoordinator =
        0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 constant s_keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 constant callbackGasLimit = 300000;
    uint16 constant requestConfirmations = 3;
    uint32 private MAX_WORDS;
    uint256 MAX_BET_AMOUNT = 5 * 10**18;
    PayableHilowContract teamContract;
    PayableHilowContract supportersContract;
    CardsHoldingInterface cardsHolding;
    Card placeholderCard = Card(0);
    GameCards placeholderGameCards =
        GameCards(placeholderCard, placeholderCard, placeholderCard);
    Game placeholderGame = Game(placeholderGameCards, 0, false, false);
    mapping(uint256 => uint256) private LOW_BET_PAYOFFS;
    mapping(uint256 => uint256) private HIGH_BET_PAYOFFS;
    mapping(address => Game) private gamesByAddr;

    event CardDrawn(address indexed player, uint256 firstDrawCard);
    event FirstBetMade(
        address indexed player,
        uint256 firstDrawCard,
        uint256 secondDrawCard,
        bool isWin
    );
    event GameFinished(
        address indexed player,
        uint256 firstDrawCard,
        uint256 secondDrawCard,
        uint256 thirdDrawCard,
        bool isWin,
        uint256 payoutMultiplier,
        uint256 payoutAmount
    );
    event DealerTipped(address indexed tipper, uint256 amount);

    constructor(
        uint64 subscriptionId,
        address payable _teamPayoutContractAddress,
        address payable _supportersPayoutContractAddress,
        address _cardsHoldingContractAddress,
        uint32 maxWords
    ) payable VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        teamContract = PayableHilowContract(_teamPayoutContractAddress);
        supportersContract = PayableHilowContract(
            _supportersPayoutContractAddress
        );
        cardsHolding = CardsHoldingInterface(_cardsHoldingContractAddress);
        MAX_WORDS = maxWords;

        setBetAmounts();
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address hilowOwner = owner();
        (bool success, bytes memory data) = payable(hilowOwner).call{
            value: balance
        }("Withdrawing funds");
        require(success, "Withdraw failed");
    }

    function viewGame(address addr)
        public
        view
        onlyOwner
        returns (Game memory)
    {
        return gamesByAddr[addr];
    }

    function viewPayoffForBet(bool higher, uint256 firstCard)
        public
        view
        returns (uint256)
    {
        require(firstCard >= 1 && firstCard <= 13, "Invalid first card");
        if (higher) return HIGH_BET_PAYOFFS[firstCard];
        else return LOW_BET_PAYOFFS[firstCard];
    }

    function tip() public payable {
        emit DealerTipped(msg.sender, msg.value);
    }

    function drawBulkRandomCards() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            MAX_WORDS
        );
    }

    //Do we need this function
    function initialCardLoad() public {
        require(AutomationAddress != address(0), "AutomationAddress null, please ask admin to set the address");
        require(
            AutomationAddress == msg.sender,
            " Only authorised address can call the function"
        );
        drawBulkRandomCards();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        cardsHolding.storeCards(randomWords);
    }

    function isGameAlreadyStarted() public view returns (bool) {
        GameCards memory currentGame = gamesByAddr[msg.sender].cards;
        if (
            (currentGame.firstDraw.value > 0 &&
                currentGame.thirdDraw.value == 0)
        ) {
            return true;
        }
        return false;
    }

    function getActiveGame() public view returns (bool, Game memory) {
        if (isGameAlreadyStarted()) {
            return (true, gamesByAddr[msg.sender]);
        }
        return (false, placeholderGame);
    }

    function drawCard() public {
        require(!isGameAlreadyStarted(), "Game already started");

        uint256 firstDrawValue;
        bool shouldTriggerDraw;
        (firstDrawValue) = cardsHolding.getFirstFlipCard();
        Card memory firstDraw = Card(firstDrawValue);

        //check this fucntion call, Dheeraj
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        GameCards memory gameCards = GameCards(
            firstDraw,
            placeholderCard,
            placeholderCard
        );
        Game memory game = Game(gameCards, 0, false, false);
        gamesByAddr[msg.sender] = game;
        emit CardDrawn(msg.sender, firstDraw.value);
    }

    function checkWin(
        uint256 cardOne,
        uint256 cardTwo,
        bool higher
    ) private pure returns (bool) {
        bool isWin;
        if (higher) {
            if (cardOne == 1) {
                if (cardTwo > cardOne) {
                    isWin = true;
                }
            } else if (cardOne == 13) {
                if (cardTwo == cardOne) {
                    isWin = true;
                }
            } else {
                if (cardTwo >= cardOne) {
                    isWin = true;
                }
            }
        } else {
            if (cardOne == 1) {
                if (cardTwo == cardOne) {
                    isWin = true;
                }
            } else if (cardOne == 13) {
                if (cardTwo < cardOne) {
                    isWin = true;
                }
            } else {
                if (cardTwo <= cardOne) {
                    isWin = true;
                }
            }
        }

        return isWin;
    }

    function getPayoutMultiplier(uint256 cardOne, bool higher)
        private
        view
        returns (uint256)
    {
        uint256 multiplier;
        if (higher) {
            multiplier = HIGH_BET_PAYOFFS[cardOne];
        } else {
            multiplier = LOW_BET_PAYOFFS[cardOne];
        }

        return multiplier;
    }

    function makeFirstBet(bool higher) public payable {
        require(msg.value <= MAX_BET_AMOUNT, "Max bet amount exceeded");
        Game memory currentGame = gamesByAddr[msg.sender];
        GameCards memory currentGameCards = currentGame.cards;
        require(
            currentGameCards.firstDraw.value > 0,
            "First card should be drawn for the game"
        );
        require(
            currentGameCards.secondDraw.value == 0,
            "Second card has already been drawn for the game"
        );
        payCommission();

        uint256 secondDrawValue;
        bool shouldTriggerDraw;
        (secondDrawValue) = cardsHolding.getNextCard();
        Card memory secondDraw = Card(secondDrawValue);
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        currentGameCards.secondDraw = secondDraw;
        currentGame.betAmount = msg.value;
        currentGame.firstPrediction = higher;
        gamesByAddr[msg.sender] = Game(
            currentGameCards,
            currentGame.betAmount,
            currentGame.firstPrediction,
            false
        );

        bool isWin;
        isWin = checkWin(
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            higher
        );
        if (!isWin) {
            gamesByAddr[msg.sender] = placeholderGame;
        }

        emit FirstBetMade(
            msg.sender,
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            isWin
        );
    }

    function makeSecondBet(bool higher) public {
        Game memory currentGame = gamesByAddr[msg.sender];
        GameCards memory currentGameCards = currentGame.cards;
        require(
            currentGameCards.firstDraw.value > 0 &&
                currentGameCards.secondDraw.value > 0,
            "First and second card should be drawn for the game"
        );
        require(
            currentGameCards.thirdDraw.value == 0,
            "Third card has already been drawn for the game"
        );

        uint256 thirdDrawValue;
        bool shouldTriggerDraw;
        (thirdDrawValue) = cardsHolding.getNextCard();
        Card memory thirdDraw = Card(thirdDrawValue);
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        currentGameCards.thirdDraw = thirdDraw;
        currentGame.secondPrediction = higher;
        gamesByAddr[msg.sender] = Game(
            currentGameCards,
            currentGame.betAmount,
            currentGame.firstPrediction,
            currentGame.secondPrediction
        );

        bool isFirstWin = checkWin(
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            currentGame.firstPrediction
        );
        bool isSecondWin = checkWin(
            currentGameCards.secondDraw.value,
            currentGameCards.thirdDraw.value,
            currentGame.secondPrediction
        );

        uint256 payoutMultiplier;
        uint256 payoutAmount;

        if (isFirstWin && isSecondWin) {
            uint256 multiplier1 = getPayoutMultiplier(
                currentGameCards.firstDraw.value,
                currentGame.firstPrediction
            );
            uint256 multiplier2 = getPayoutMultiplier(
                currentGameCards.secondDraw.value,
                currentGame.secondPrediction
            );
            payoutAmount =
                (currentGame.betAmount * multiplier1 * multiplier2) /
                10000;
            (bool success, bytes memory data) = payable(msg.sender).call{
                value: payoutAmount
            }("Sending payout");
            require(success, "Payout failed");
        }

        emit GameFinished(
            msg.sender,
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            currentGameCards.thirdDraw.value,
            isSecondWin,
            payoutMultiplier,
            payoutAmount
        );
    }

    function payCommission() internal {
        uint256 teamCommission = SafeMath.div(SafeMath.mul(msg.value, 1), 100); // 1% to team
        uint256 supportersCommission = SafeMath.div(
            SafeMath.mul(msg.value, 4),
            100
        ); // 4% to supporters

        bool tsuccess = teamContract.sendFunds{value: teamCommission}();
        require(tsuccess, "Team commission payout failed.");
        bool ssuccess = supportersContract.sendFunds{
            value: supportersCommission
        }();
        require(ssuccess, "Supporters commission payout failed.");
    }

    function setAtomationAddress(address _automation) public onlyOwner {
        require(_automation != address(0), "Invalid address");

        AutomationAddress = _automation;
    }

    function setBetAmounts() private {
        // Set low bet payoffs
        LOW_BET_PAYOFFS[1] = 200;
        LOW_BET_PAYOFFS[2] = 192;
        LOW_BET_PAYOFFS[3] = 184;
        LOW_BET_PAYOFFS[4] = 176;
        LOW_BET_PAYOFFS[5] = 169;
        LOW_BET_PAYOFFS[6] = 161;
        LOW_BET_PAYOFFS[7] = 153;
        LOW_BET_PAYOFFS[8] = 146;
        LOW_BET_PAYOFFS[9] = 138;
        LOW_BET_PAYOFFS[10] = 130;
        LOW_BET_PAYOFFS[11] = 123;
        LOW_BET_PAYOFFS[12] = 115;
        LOW_BET_PAYOFFS[13] = 100;

        // Set low bet payoffs
        HIGH_BET_PAYOFFS[1] = 100;
        HIGH_BET_PAYOFFS[2] = 115;
        HIGH_BET_PAYOFFS[3] = 123;
        HIGH_BET_PAYOFFS[4] = 130;
        HIGH_BET_PAYOFFS[5] = 138;
        HIGH_BET_PAYOFFS[6] = 146;
        HIGH_BET_PAYOFFS[7] = 153;
        HIGH_BET_PAYOFFS[8] = 161;
        HIGH_BET_PAYOFFS[9] = 169;
        HIGH_BET_PAYOFFS[10] = 176;
        HIGH_BET_PAYOFFS[11] = 184;
        HIGH_BET_PAYOFFS[12] = 192;
        HIGH_BET_PAYOFFS[13] = 200;
    }
}
