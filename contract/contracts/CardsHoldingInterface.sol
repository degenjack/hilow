// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CardsHoldingInterface {
    struct Card {
        uint256 value;
    }

    function getNextCard()
        external
        returns (Card memory card, bool shouldTriggerDraw);

    function storeCards(uint256[] memory cardValues) external;
}
