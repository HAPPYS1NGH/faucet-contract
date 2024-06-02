// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from
    "/Users/happy/Documents/Blockchain/Arbitrum/faucet-contract/lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    //////////////////////////////
    // ERRORS ///////////////////
    ////////////////////////////

    error AlreadyClaimedByFIDWithInADay();
    error AlreadyClaimedByAddressWithInADay();
    error EnoughBalance();
    error UnableToTransfer();

    //////////////////////////////
    // STATE VARIABLES //////////
    ////////////////////////////

    mapping(address => uint256) public lastDripTimestampByAddress;
    mapping(uint256 => uint256) public lastDripTimestampByFid;

    //////////////////////////////
    // EVENTS ///////////////////
    ////////////////////////////

    event TokensDripped(address indexed to, uint256 indexed fid);
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

    function dripTokensToAddress(address to, uint256 fid, uint256 amount) external onlyOwner {
        if (isTokenDrippedToAddressInLast24Hours(to)) {
            revert AlreadyClaimedByAddressWithInADay();
        }

        if (isTokenDrippedToFidInLast24Hours(fid)) {
            revert AlreadyClaimedByFIDWithInADay();
        }

        if (isBalanceAboveThreshold(to)) {
            revert EnoughBalance();
        }

        lastDripTimestampByAddress[to] = block.timestamp;
        lastDripTimestampByFid[fid] = block.timestamp;

        emit TokensDripped(to, fid);

        (bool success,) = to.call{value: amount}("");

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

    function isTokenDrippedToFidInLast24Hours(uint256 fid) public view returns (bool) {
        return lastDripTimestampByFid[fid] > block.timestamp - 1 days;
    }

    function isBalanceAboveThreshold(address add) public view returns (bool) {
        return add.balance > 0.1 ether;
    }
}
