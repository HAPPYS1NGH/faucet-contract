// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TelegramFaucet is Ownable {
    //////////////////////////////
    // ERRORS ///////////////////
    ////////////////////////////

    error AlreadyClaimedByUsernameWithInADay();
    error AlreadyClaimedByAddressWithInADay();
    error EnoughBalance();
    error UnableToTransfer();

    //////////////////////////////
    // STATE VARIABLES //////////
    ////////////////////////////

    mapping(address => uint256) public lastDripTimestampByAddress;
    mapping(bytes => uint256) public lastDripTimestampByUsername;

    //////////////////////////////
    // EVENTS ///////////////////
    ////////////////////////////

    event TokensDripped(address indexed to, bytes indexed username);
    event TokensReceived(address indexed from);

    //////////////////////////////
    // FUNCTIONS ////////////////
    ////////////////////////////

    constructor() Ownable(msg.sender) {}

    receive() external payable {
        emit TokensReceived(msg.sender);
    }

    fallback() external payable {
        emit TokensReceived(msg.sender);
    }

    //////////////////////////////
    // EXTERNAL FUNCTIONS /////////
    ////////////////////////////

    function dripTokensToAddress(address to, bytes calldata username, uint256 amount) external onlyOwner {
        if (isTokenDrippedToAddressInLast24Hours(to)) {
            revert AlreadyClaimedByAddressWithInADay();
        }

        if (isTokenDrippedToUsernameInLast24Hours(username)) {
            revert AlreadyClaimedByUsernameWithInADay();
        }

        if (isBalanceAboveThreshold(to)) {
            revert EnoughBalance();
        }
        lastDripTimestampByAddress[to] = block.timestamp;
        lastDripTimestampByUsername[username] = block.timestamp;

        emit TokensDripped(to, username);

        (bool success,) = to.call{value: amount}("");

        if (!success) {
            revert UnableToTransfer();
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert UnableToTransfer();
        }
    }

    /////////////////////////////////
    // VIEW AND PUBLIC FUNCTIONS ////
    /////////////////////////////////

    function isTokenDrippedToAddressInLast24Hours(address add) public view returns (bool) {
        return lastDripTimestampByAddress[add] > block.timestamp - 1 days;
    }

    function isTokenDrippedToUsernameInLast24Hours(bytes memory username) public view returns (bool) {
        return lastDripTimestampByUsername[username] > block.timestamp - 1 days;
    }

    function isBalanceAboveThreshold(address add) public view returns (bool) {
        return add.balance > 1 ether;
    }
}
