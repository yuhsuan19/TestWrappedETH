// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {WrappedETH} from "../src/WrappedETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WrappedETHTest is Test {
    
    event Deposit(address from, uint256 amount) ;

    WrappedETH instance;
    address user1;

    function setUp() public {
        user1 = makeAddr("user1");
        instance = new WrappedETH();
    }

    function testDeposit() public {   
        uint256 userBalanceBefore = IERC20(address(instance)).balanceOf(user1);
        uint256 contractBalanceBefore = address(instance).balance;
        uint256 depositAmount = 0.5 ether;

        deal(user1, depositAmount);

        vm.startPrank(user1);
        
        vm.expectEmit(address(instance));
        emit Deposit(user1, depositAmount); // test case 3

        (bool success, ) = address(instance).call {value: depositAmount}(abi.encodeWithSignature("deposit()"));
        vm.stopPrank();

        uint256 userBalanceAfter = IERC20(address(instance)).balanceOf(user1);
        uint256 contractBalanceAfter = address(instance).balance;

        assert(success);
        assertEq((userBalanceAfter - userBalanceBefore), depositAmount);  // test case 1
        assertEq((contractBalanceAfter - contractBalanceBefore), depositAmount); // test case 2
    }
}