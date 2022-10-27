// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./CardsHoldingInterface.sol";

contract CardsHolding is CardsHoldingInterface {
    uint32 private MAX_WORDS;
    uint32 private BUFFER_WORDS;
    Card[20] internal cards;
    using Counters for Counters.Counter;
    Counters.Counter private _currentCard;

    constructor(uint32 maxWords) {
        require(maxWords <= 20, "maxWords should be less than 20");
        MAX_WORDS = maxWords;
        BUFFER_WORDS = maxWords - 3;
    }

    function getNextCard()
        external
        returns (Card memory card, bool shouldTriggerDraw)
    {
        if (_currentCard.current() > BUFFER_WORDS) {
            shouldTriggerDraw = true;
        }
        if (_currentCard.current() >= MAX_WORDS) {
            _currentCard.reset();
        }
        uint256 currentCard = _currentCard.current();
        _currentCard.increment();
        card = cards[currentCard];
    }

    function storeCards(uint256[] memory cardValues) external {
        for (uint256 index = 0; index < MAX_WORDS; index++) {
            cards[index] = Card((cardValues[index] % 13) + 1);
        }
        _currentCard.reset();
    }
}
