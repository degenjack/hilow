// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface CardsHoldingInterface {
    function getNextCard() external returns (uint256 card);

    function storeCards(uint256[] memory cardValues) external;

    function getFirstFlipCard() external returns (uint256);
}
