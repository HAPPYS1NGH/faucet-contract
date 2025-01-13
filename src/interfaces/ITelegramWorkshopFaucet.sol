// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITelegramWorkshopFaucet {
    //////////////////////////////
    // ERRORS ///////////////////
    ////////////////////////////

    error AlreadyClaimedByUsernameWithInTimeframe();
    error AlreadyClaimedByAddressWithInTimeframe();
    error EnoughBalance();
    error UnableToTransfer();
    error InvalidDripAmount();
    error InvalidBalanceThreshold();

    //////////////////////////////
    // EVENTS ///////////////////
    ////////////////////////////

    event TokensDripped(address indexed to, bytes indexed username);
    event TokensReceived(address indexed from);
    event ParametersUpdated(uint256 dripAmount, uint256 balanceThreshold);

    //////////////////////////////
    // FUNCTIONS ////////////////
    ////////////////////////////

    //////////////////////////////
    // EXTERNAL FUNCTIONS /////////
    ////////////////////////////

    function dripTokensToAddress(address to, bytes calldata username, uint256 amount) external;
    function updateParameters(uint256 _dripAmount, uint256 _balanceThreshold, uint256 _maxDripAmount) external;
    function withdraw() external;

    /////////////////////////////////
    // VIEW FUNCTIONS ///////////////
    /////////////////////////////////

    function isTokenDrippedToAddressInTimeframe(address add) external view returns (bool);

    function isTokenDrippedToUsernameInTimeframe(bytes memory username) external view returns (bool);

    function isBalanceAboveThreshold(address add) external view returns (bool);
}
