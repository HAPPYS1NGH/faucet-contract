// SPDX-License-Identifier: MIT

import {ITelegramWorkshopFaucet} from "../interfaces/ITelegramWorkshopFaucet.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.20;

contract TelegramWorkshopFaucet is ITelegramWorkshopFaucet, Ownable {
    //////////////////////////////
    // STATE VARIABLES //////////
    ////////////////////////////

    mapping(address => uint256) public lastDripTimestampByAddress;
    mapping(bytes => uint256) public lastDripTimestampByUsername;
    uint256 public dripAmount;
    uint256 public balanceThreshold;
    address deployer;

    //////////////////////////////
    // Modifier /////////////////
    ////////////////////////////

    modifier onlyOwners() {
        require(msg.sender == owner() || msg.sender == deployer, "Only owner can call this function");
        _;
    }

    //////////////////////////////
    // FUNCTIONS ////////////////
    ////////////////////////////

    constructor(address owner, uint256 _dripAmount, uint256 _balanceThreshold, address _deployer) Ownable(owner) {
        dripAmount = _dripAmount;
        balanceThreshold = _balanceThreshold;
        deployer = _deployer;
        emit ParametersUpdated(_dripAmount, _balanceThreshold);
    }

    receive() external payable {
        emit TokensReceived(msg.sender);
    }

    fallback() external payable {
        emit TokensReceived(msg.sender);
    }

    //////////////////////////////
    // EXTERNAL FUNCTIONS /////////
    ////////////////////////////

    function dripTokensToAddress(address to, bytes calldata username, uint256 amount) external onlyOwners {
        if (isTokenDrippedToAddressInTimeframe(to)) {
            revert AlreadyClaimedByAddressWithInTimeframe();
        }

        if (isTokenDrippedToUsernameInTimeframe(username)) {
            revert AlreadyClaimedByUsernameWithInTimeframe();
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

    function updateParameters(uint256 _dripAmount, uint256 _balanceThreshold, uint256 _maxDripAmount)
        external
        onlyOwners
    {
        if (_dripAmount == 0) {
            revert InvalidDripAmount();
        }
        if (_balanceThreshold == 0) {
            revert InvalidBalanceThreshold();
        }
        dripAmount = _dripAmount;
        balanceThreshold = _balanceThreshold;
        emit ParametersUpdated(_dripAmount, _balanceThreshold);
    }

    function withdraw() external onlyOwners {
        (bool success,) = deployer.call{value: address(this).balance}("");
        if (!success) {
            revert UnableToTransfer();
        }
    }

    /////////////////////////////////
    // VIEW FUNCTIONS ////
    /////////////////////////////////

    function isTokenDrippedToAddressInTimeframe(address add) public view returns (bool) {
        return lastDripTimestampByAddress[add] > block.timestamp - 1 days;
    }

    function isTokenDrippedToUsernameInTimeframe(bytes memory username) public view returns (bool) {
        return lastDripTimestampByUsername[username] > block.timestamp - 1 days;
    }

    function isBalanceAboveThreshold(address add) public view returns (bool) {
        return add.balance > balanceThreshold;
    }
}
