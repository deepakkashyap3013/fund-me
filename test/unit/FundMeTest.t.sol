// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// what can we do to work with addresses outside our system?
// 1. Unit
//    - Testing a specific part of our code
// 2. Integration
//   - Testing how our code works with other contracts
// 3. Forked
//   - Testing how our code works with the simulated real environment
// 4. Staging
//  - Testing how our code works with the real environment that is not prod

// Lifecycle of test -> run setUp -> run test function -> setUp so each tests are isolated

contract FundMeTest is Test, Script {
    FundMe fundme;
    address USER = makeAddr("USER");
    uint256 SEND_VALUE = 0.1 ether;
    uint256 STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarisFive() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testGetVersion() public view {
        if (block.chainid == 11155111) {
            assertEq(fundme.getVersion(), 4);
        } else if (block.chainid == 1) {
            assertEq(fundme.getVersion(), 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundme.fund{value: 0}();
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundDataStructures() public funded {
        assertEq(fundme.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public funded {
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = address(fundme.getOwner()).balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = address(fundme.getOwner()).balance;
        uint256 endingFundMeBalance = address(fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_BALANCE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = address(fundme.getOwner()).balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        // Act
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);
        assert(
            startingOwnerBalance + startingFundMeBalance ==
                address(fundme.getOwner()).balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundme.getOwner().balance - startingOwnerBalance
        );
    }
}
