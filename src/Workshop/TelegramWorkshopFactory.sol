// SPDX-License-Identifier: MIT
import "../interfaces/ITelegramWorkshopFactory.sol";
import "../interfaces/ITelegramWorkshopFaucet.sol";
import "./TelegramWorkshopFaucet.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.20;

contract TelegramWorkshopFactory is ITelegramWorkshopFactory, Ownable {
    //////////////////////////////
    // State Variables ///////////
    //////////////////////////////

    mapping(uint256 => address) public workshopContractsByCode;
    mapping(address => uint256) public codeByWorkshopContract;
    mapping(address => address) public ownerofWorkshopContract;

    uint256 public contractCount;
    //////////////////////////////
    // Constructor ///////////////
    //////////////////////////////

    constructor() Ownable(msg.sender) {}

    //////////////////////////////
    // Write Functions ///////////
    //////////////////////////////

    /**
     * @notice Create a new workshop contract
     * @param dripAmount The amount of tokens to drip
     * @param balanceThreshold The balance threshold
     * @param code The code of the workshop contract
     * @return address The address of the workshop contract
     */
    function createWorkshopContract(uint256 dripAmount, uint256 balanceThreshold, uint256 code)
        external
        payable
        returns (address)
    {
        if (dripAmount == 0) {
            revert InvalidDripAmount();
        }
        if (balanceThreshold == 0) {
            revert InvalidBalanceThreshold();
        }
        if (workshopContractsByCode[code] != address(0)) {
            revert AlreadyWorkshopWithTheCode();
        }
        if (ownerofWorkshopContract[msg.sender] != address(0)) {
            revert AlreadyWorkshopWithTheAddress();
        }
        TelegramWorkshopFaucet workshopContract =
            new TelegramWorkshopFaucet(owner(), dripAmount, balanceThreshold, msg.sender);
        workshopContractsByCode[code] = address(workshopContract);
        codeByWorkshopContract[address(workshopContract)] = code;
        ownerofWorkshopContract[address(workshopContract)] = msg.sender;
        contractCount++;
        emit InitializedWorkshopFaucet(msg.sender, address(workshopContract), code, dripAmount, balanceThreshold);
        return address(workshopContract);
    }

    /**
     * @notice Neutralize a workshop contract
     * @param code The code of the workshop contract
     * @return bool True if the workshop contract is neutralized
     */
    function neutralizeWorkshopContract(uint256 code) external returns (bool) {
        address workshopContract = workshopContractsByCode[code];
        require(ownerofWorkshopContract[workshopContract] == msg.sender, "Only the owner can neutralize the contract");
        ITelegramWorkshopFaucet(workshopContract).withdraw();
        delete workshopContractsByCode[code];
        delete codeByWorkshopContract[workshopContract];
        delete ownerofWorkshopContract[workshopContract];
        emit NeutralisedWorkshopFaucet(workshopContract, msg.sender, code);
        return true;
    }

    //////////////////////////////
    // View Functions ////////////
    //////////////////////////////

    /**
     * @notice Get workshop contract address by code
     * @param code The code of the workshop contract
     * @return address The address of the workshop contract
     */
    function getWorkshopContractByCode(uint256 code) external view override returns (address) {
        return workshopContractsByCode[code];
    }

    function getWorkshopContractByAddress(address) external view returns (address) {
        return ownerofWorkshopContract[msg.sender];
    }

    function getWorkshopContractCount() external view returns (uint256) {
        return contractCount;
    }
}
