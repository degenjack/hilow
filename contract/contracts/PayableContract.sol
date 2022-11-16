// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PayableHilowContract {
    address _owner;

    constructor() {
        _owner = payable(msg.sender);
    }

    function sendFunds() external payable returns (bool) {
        return true;
    }

    function withdrawAll() external {
        require(msg.sender == _owner, "onlyOwner can call withdraw");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function changeOwner(address _newOwner) external {
        require(
            msg.sender == _owner,
            "Only owner can change the exsistign owner"
        );

        _owner = _newOwner;
    }

    // fallback() external payable {}

    // receive() external payable {
    //     // React to receiving ether
    // }
}
