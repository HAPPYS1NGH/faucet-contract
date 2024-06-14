// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TelegramFaucet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FaucetTest is Test {
    TelegramFaucet public faucet;
    address public owner = address(1);
    address public user = address(2);

    event TokensDripped(address indexed to, bytes indexed username);

    function setUp() public {
        // Set up the faucet contract
        vm.warp(1641070800);
        vm.deal(owner, 10 ether); // Give the owner 10 ether
        vm.startPrank(owner);
        faucet = new TelegramFaucet();
        console.log("TelegramFaucet address: %s", address(faucet));
        vm.deal(address(faucet), 1 ether); // Give the faucet some ether
        vm.stopPrank();

        // Give the user some initial balance
        vm.deal(user, 0.05 ether);
    }

    function test_DripTokensToAddress() public {
        vm.startPrank(owner);

        uint256 initialBalance = user.balance;
        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        faucet.dripTokensToAddress(user, username, amount);

        assertEq(user.balance, initialBalance + amount, "User balance should increase by amount dripped");
        assertEq(faucet.lastDripTimestampByAddress(user), block.timestamp, "Timestamp should be updated");
        assertEq(faucet.lastDripTimestampByUsername(username), block.timestamp, "Username timestamp should be updated");

        vm.stopPrank();
    }

    function test_CannotDripTokensToAddressWithin24Hours() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        // Drip tokens to user
        faucet.dripTokensToAddress(user, username, amount);

        // Try to drip again within 24 hours
        vm.expectRevert(TelegramFaucet.AlreadyClaimedByAddressWithInADay.selector);
        faucet.dripTokensToAddress(user, username, amount);

        vm.stopPrank();
    }

    function test_CannotDripTokensToUsernameWithin24Hours() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        // Drip tokens to user
        faucet.dripTokensToAddress(user, username, amount);

        // Try to drip to another address with the same username within 24 hours
        address anotherUser = address(3);

        vm.expectRevert(TelegramFaucet.AlreadyClaimedByUsernameWithInADay.selector);
        faucet.dripTokensToAddress(anotherUser, username, amount);

        vm.stopPrank();
    }

    function test_CannotDripTokensToAddressAboveThreshold() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        // Give the user a balance above the threshold
        vm.deal(user, 1.2 ether);

        // Try to drip tokens to user with balance above threshold
        vm.expectRevert(TelegramFaucet.EnoughBalance.selector);
        faucet.dripTokensToAddress(user, username, amount);

        vm.stopPrank();
    }

    function test_EmitTokensDrippedEvent() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        // Expect the TokensDripped event to be emitted
        vm.expectEmit(true, true, false, false);
        emit TokensDripped(user, username);

        // Drip tokens to user
        faucet.dripTokensToAddress(user, username, amount);

        vm.stopPrank();
    }

    function test_DripTokensToMultipleUsers() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username1 = "user123";
        bytes memory username2 = "user456";
        address user2 = address(3);

        // Give the user2 some initial balance
        vm.deal(user2, 0.05 ether);

        // Drip tokens to user1
        faucet.dripTokensToAddress(user, username1, amount);
        // Drip tokens to user2
        faucet.dripTokensToAddress(user2, username2, amount);

        assertEq(user.balance, 0.06 ether, "User1 balance should increase by amount dripped");
        assertEq(user2.balance, 0.06 ether, "User2 balance should increase by amount dripped");

        vm.stopPrank();
    }

    function test_VerifyContractBalanceAfterMultipleDrips() public {
        vm.startPrank(owner);

        uint256 amount = 0.01 ether;
        bytes memory username1 = "user123";
        bytes memory username2 = "user456";
        address user2 = address(3);

        // Give the user2 some initial balance
        vm.deal(user2, 0.05 ether);

        // Drip tokens to user1
        faucet.dripTokensToAddress(user, username1, amount);
        // Drip tokens to user2
        faucet.dripTokensToAddress(user2, username2, amount);

        uint256 expectedBalance = 1 ether - 2 * amount;
        assertEq(
            address(faucet).balance,
            expectedBalance,
            "TelegramFaucet contract balance should decrease by the dripped amounts"
        );

        vm.stopPrank();
    }

    function test_ReceiveFunction() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(faucet).call{value: 0.1 ether}("");
        assertTrue(success, "Receive function should accept ether");
        assertEq(address(faucet).balance, 1.1 ether, "TelegramFaucet balance should increase by received amount");
    }

    function test_FallbackFunction() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(faucet).call{value: 0.1 ether}("random_data");
        assertTrue(success, "Fallback function should accept ether");
        assertEq(address(faucet).balance, 1.1 ether, "TelegramFaucet balance should increase by received amount");
    }

    function test_OnlyOwnerCanDripTokens() public {
        vm.startPrank(user); // Non-owner trying to drip tokens

        uint256 amount = 0.01 ether;
        bytes memory username = "user123";

        // Try to drip tokens as a non-owner
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        faucet.dripTokensToAddress(user, username, amount);

        vm.stopPrank();
    }

    function test_withdraw() public {
        vm.startPrank(owner);
        uint256 faucetBalance = address(faucet).balance;
        uint256 ownerBalance = owner.balance;
        // Withdraw the contract balance
        faucet.withdraw();

        assertEq(address(faucet).balance, 0, "TelegramFaucet balance should be 0 after withdrawal");
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
