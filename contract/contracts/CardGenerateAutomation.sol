// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Hilow.sol";
import "./CardsHolding.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract Counter is AutomationCompatibleInterface {
    /**
     * Public counter variable
     */
    uint256 public counter;
    Hilow public hillowContract;
    CardsHolding public cardsHoldingContract;
    address public _owner;
    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor(
        uint256 updateInterval,
        address _hilloAddress,
        address _cardholding
    ) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        hillowContract = Hilow(payable(_hilloAddress));
        cardsHoldingContract = CardsHolding(payable(_cardholding));
        counter = 0;
        _owner = msg.sender;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool,
            bytes memory /* performData */
        )
    {
        bool upkeepNeeded = true;
        uint256 length = cardsHoldingContract.getStoredCardsLength();
        if (length > 2999) {
            upkeepNeeded = false;
        }
        return (upkeepNeeded, "");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        hillowContract.initialCardLoad();
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function setHiContractAddress(address _hicontract) external {
        require(msg.sender == _owner, "only owner can cal this fucntion");
        require(_hicontract != address(0), "Invalid address");
        hillowContract = Hilow(payable(_hicontract));
    }

    function updateCardHoldingaddress(address _cardContract) external {
        require(msg.sender == _owner, "only owner can cal this fucntion");
        require(_cardContract != address(0), "Invalid address");
        cardsHoldingContract = CardsHolding(payable(_cardContract));
    }
}
