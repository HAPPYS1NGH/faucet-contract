// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Faucet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FaucetTest is Test {
    Faucet public faucet;
    address public owner = address(1);
    address public user = address(2);

    event TokensDripped(address indexed to, uint256 indexed fid);

    function setUp() public {
        // Set up the faucet contract
        vm.warp(1641070800);
        vm.deal(owner, 10 ether); // Give the owner 10 ether
        vm.startPrank(owner);
        faucet = new Faucet();
        console.log("Faucet address: %s", address(faucet));
        vm.deal(address(faucet), 1 ether); // Give the faucet some ether
        vm.stopPrank();

        // Give the user some initial balance
        vm.deal(user, 0.05 ether);
    }

    function test_DripTokensToAddress() public {
        vm.startPrank(owner);

        uint256 initialBalance = user.balance;
        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        faucet.dripTokensToAddress(user, fid, amount);

        assertEq(user.balance, initialBalance + amount, "User balance should increase by amount dripped");
        assertEq(faucet.lastDripTimestampByAddress(user), block.timestamp, "Timestamp should be updated");
        assertEq(faucet.lastDripTimestampByFid(fid), block.timestamp, "FID timestamp should be updated");

        vm.stopPrank();
    }

    function test_CannotDripTokensToAddressWithin24Hours() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        // Drip tokens to user
        faucet.dripTokensToAddress(user, fid, amount);

        // Try to drip again within 24 hours
        vm.expectRevert(Faucet.AlreadyClaimedByAddressWithInADay.selector);
        faucet.dripTokensToAddress(user, fid, amount);

        vm.stopPrank();
    }

    function test_CannotDripTokensToFidWithin24Hours() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        // Drip tokens to user
        faucet.dripTokensToAddress(user, fid, amount);

        // Try to drip to another address with the same FID within 24 hours
        address anotherUser = address(3);

        vm.expectRevert(Faucet.AlreadyClaimedByFIDWithInADay.selector);
        faucet.dripTokensToAddress(anotherUser, fid, amount);

        vm.stopPrank();
    }

    function test_CannotDripTokensToAddressAboveThreshold() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        // Give the user a balance above the threshold
        vm.deal(user, 0.2 ether);

        // Try to drip tokens to user with balance above threshold
        vm.expectRevert(Faucet.EnoughBalance.selector);
        faucet.dripTokensToAddress(user, fid, amount);

        vm.stopPrank();
    }

    function test_EmitTokensDrippedEvent() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        // Expect the TokensDripped event to be emitted
        vm.expectEmit(true, true, false, false);
        emit TokensDripped(user, fid);

        // Drip tokens to user
        faucet.dripTokensToAddress(user, fid, amount);

        vm.stopPrank();
    }

    function test_DripTokensToMultipleUsers() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid1 = 123;
        uint256 fid2 = 456;
        address user2 = address(3);

        // Give the user2 some initial balance
        vm.deal(user2, 0.05 ether);

        // Drip tokens to user1
        faucet.dripTokensToAddress(user, fid1, amount);
        // Drip tokens to user2
        faucet.dripTokensToAddress(user2, fid2, amount);

        assertEq(user.balance, 0.06 ether, "User1 balance should increase by amount dripped");
        assertEq(user2.balance, 0.06 ether, "User2 balance should increase by amount dripped");

        vm.stopPrank();
    }

    function test_VerifyContractBalanceAfterMultipleDrips() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        uint256 fid1 = 123;
        uint256 fid2 = 456;
        address user2 = address(3);

        // Give the user2 some initial balance
        vm.deal(user2, 0.05 ether);

        // Drip tokens to user1
        faucet.dripTokensToAddress(user, fid1, amount);
        // Drip tokens to user2
        faucet.dripTokensToAddress(user2, fid2, amount);

        uint256 expectedBalance = 1 ether - 2 * amount;
        assertEq(
            address(faucet).balance, expectedBalance, "Faucet contract balance should decrease by the dripped amounts"
        );

        vm.stopPrank();
    }

    function test_ReceiveFunction() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(faucet).call{value: 0.1 ether}("");
        assertTrue(success, "Receive function should accept ether");
        assertEq(address(faucet).balance, 1.1 ether, "Faucet balance should increase by received amount");
    }

    function test_FallbackFunction() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(faucet).call{value: 0.1 ether}("random_data");
        assertTrue(success, "Fallback function should accept ether");
        assertEq(address(faucet).balance, 1.1 ether, "Faucet balance should increase by received amount");
    }

    function test_OnlyOwnerCanDripTokens() public {
        vm.startPrank(user); // Non-owner trying to drip tokens

        uint256 amount = 0.01 ether;
        uint256 fid = 123;

        // Try to drip tokens as a non-owner
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        faucet.dripTokensToAddress(user, fid, amount);

        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(owner);
        uint256 faucetBalance = address(faucet).balance;
        uint256 ownerBalance = owner.balance;
        // Withdraw the contract balance
        faucet.withdraw();

        assertEq(address(faucet).balance, 0, "Faucet balance should be 0 after withdrawal");
        assertEq(owner.balance, ownerBalance + faucetBalance, "Owner balance should increase by the contract balance");

        vm.stopPrank();
    }

    function test_UnAuthorisedWithdrawal() public {
        vm.startPrank(user);
        // Try to withdraw as a non-owner
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        faucet.withdraw();
        vm.stopPrank();
    }
}
