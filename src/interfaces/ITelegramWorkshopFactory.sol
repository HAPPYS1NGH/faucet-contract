// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ITelegramWorkshopFactory {
    //////////////////////////////
    // ERRORS ///////////////////
    ////////////////////////////

    error AlreadyWorkshopWithTheCode();
    error AlreadyWorkshopWithTheAddress();
    error EnoughBalance();
    error UnableToTransfer();
    error InvalidDripAmount();
    error InvalidBalanceThreshold();
    error UnauthorizedAccess(address caller);
    error InvalidCode(uint256 code);

    //////////////////////////////
    // EVENTS ///////////////////
    ////////////////////////////

    event InitializedWorkshopFaucet(
        address indexed deployer,
        address indexed contractAddress,
        uint256 indexed code,
        uint256 dripAmount,
        uint256 balanceThreshold
    );
    event NeutralisedWorkshopFaucet(address indexed workshopContractAddress, address indexed neutralizer, uint256);

    //////////////////////////////
    // WRITE FUNCTIONS //////////
    ////////////////////////////

    function createWorkshopContract(uint256 dripAmount, uint256 balanceThreshold, uint256 code)
        external
        payable
        returns (address);
    function neutralizeWorkshopContract(uint256 code) external returns (bool);

    //////////////////////////////
    // VIEW FUNCTIONS ///////////
    ////////////////////////////

    function getWorkshopContractByAddress(address) external view returns (address);
    function getWorkshopContractByCode(uint256) external view returns (address);
    function getWorkshopContractCount() external view returns (uint256);
}
