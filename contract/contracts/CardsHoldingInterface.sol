// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CardsHoldingInterface {
    function getNextCard()
        external
        returns (uint256 card, bool shouldTriggerDraw);

    function storeCards(uint256[] memory cardValues) external;
}
