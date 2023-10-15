// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {WrappedETH} from "../src/WrappedETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WrappedETHTest is Test {
    
    event Deposit(address from, uint256 amount) ;
    event Withdraw(address from, uint256 amount);

    WrappedETH instance;
    address user1;
    address user2;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        instance = new WrappedETH();
    }

    function testDeposit() public {
        uint256 depositAmount = 0.5 ether;   
        deal(user1, depositAmount);

        uint256 userBalanceBefore = IERC20(address(instance)).balanceOf(user1);
        uint256 contractBalanceBefore = address(instance).balance;

        vm.startPrank(user1);
        // test case 3: deposit 應該要 emit Deposit event
        vm.expectEmit(address(instance));
        emit Deposit(user1, depositAmount);
        (bool success, ) = address(instance).call {value: depositAmount}(abi.encodeWithSignature("deposit()"));
        vm.stopPrank();

        uint256 userBalanceAfter = IERC20(address(instance)).balanceOf(user1);
        uint256 contractBalanceAfter = address(instance).balance;

        assert(success);
        // test case 1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
        assertEq((userBalanceAfter - userBalanceBefore), depositAmount);
        // test case 2: deposit 應該將 msg.value 的 ether 轉入合約
        assertEq((contractBalanceAfter - contractBalanceBefore), depositAmount);
    }

    function testWithdraw() public {
        uint256 withdrawAmount = 0.5 ether;
        deal(user1, withdrawAmount);
        uint256 userBalance = user1.balance;

        // deposit
        vm.startPrank(user1);
        (bool depositSuccess, ) = address(instance).call {value: withdrawAmount}(abi.encodeWithSignature("deposit()"));
        vm.stopPrank();
        assert(depositSuccess);

        uint256 userWETHBalanceBefore = IERC20(address(instance)).balanceOf(user1);
        assertEq(userWETHBalanceBefore, withdrawAmount);
        uint256 totalSupplyBefore = IERC20(address(instance)).totalSupply();

        // withdraw        
        vm.startPrank(user1);
        // test case 6: withdraw 應該要 emit Withdraw event
        vm.expectEmit(address(instance));
        emit Withdraw(user1, withdrawAmount);
        (bool withdrawSuccess, ) = address(instance).call(abi.encodeWithSignature("withdraw(uint256)", withdrawAmount)); 
        vm.stopPrank();

        uint256 userWETHBalanceAfter = IERC20(address(instance)).balanceOf(user1);

        assert(withdrawSuccess);
        //test case 4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
        assertEq(IERC20(address(instance)).totalSupply(), (totalSupplyBefore - withdrawAmount));
        // test case 5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
        assertEq(userWETHBalanceAfter, (userWETHBalanceBefore - withdrawAmount));
        assertEq(user1.balance, userBalance); 

    }

    function testTransfer() public {
        deal(user1, 1 ether);
        // deposit
        vm.startPrank(user1);
        (bool depositSuccess, ) = address(instance).call {value: 1 ether}(abi.encodeWithSignature("deposit()"));
        vm.stopPrank();
        assert(depositSuccess);
        uint256 user1BalanceBefore = IERC20(address(instance)).balanceOf(user1);
        assertEq(user1BalanceBefore, 1 ether);

        // transfer
        uint256 transferAmount = 0.87 ether;
        uint256 user2BalanceBefore = IERC20(address(instance)).balanceOf(user2);
        vm.startPrank(user1);
        (bool transferSuccess, ) = address(instance).call(abi.encodeWithSignature("transfer(address,uint256)", user2, transferAmount));
        vm.stopPrank();

        uint256 user1BalanceAfter = IERC20(address(instance)).balanceOf(user1);
        uint256 user2BalanceAfter = IERC20(address(instance)).balanceOf(user2);

        assert(transferSuccess);
        // test case 7: transfer 應該要將 erc20 token 轉給別人
        assertEq((user2BalanceAfter - user2BalanceBefore), transferAmount);
        assertEq((user1BalanceBefore - transferAmount), user1BalanceAfter);
    }

    function testApproveAndTransferFrom() public {
        deal(user1, 1 ether);
        // deposit
        vm.startPrank(user1);
        (bool depositSuccess, ) = address(instance).call {value: 1 ether}(abi.encodeWithSignature("deposit()"));
        vm.stopPrank();
        assert(depositSuccess);

        // approve
        uint256 approveAmount = 0.5 ether;

        vm.startPrank(user1);
        (bool approveSuccess, ) = address(instance).call(abi.encodeWithSignature("approve(address,uint256)", user2, approveAmount));
        vm.stopPrank();
        assert(approveSuccess);
        (bool allowanceSuccess, bytes memory allowanceData) = address(instance).call(abi.encodeWithSignature("allowance(address,address)", user1, user2));
        assert(allowanceSuccess);
        uint256 allowance = abi.decode(allowanceData, (uint256));
        // test case 8: approve 應該要給他人 allowance
        assertEq(allowance, approveAmount);
        
        // transferFrom
        uint256 transferFromAmount = 0.3 ether;
        uint256 user1BalanceBefore = IERC20(address(instance)).balanceOf(user1);
        uint256 user2BalanceBefore = IERC20(address(instance)).balanceOf(user2);

        vm.startPrank(user2);
        (bool transferFromSuccess,) = address(instance).call(abi.encodeWithSignature("transferFrom(address,address,uint256)",user1, user2, transferFromAmount));
        vm.stopPrank();

        uint256 user1BalanceAfter = IERC20(address(instance)).balanceOf(user1);
        uint256 user2BalanceAfter = IERC20(address(instance)).balanceOf(user2);

        // test case 9: transferFrom 應該要可以使用他人的 allowance
        assert(transferFromSuccess);
        // test case 10: transferFrom 後應該要減除用完的 allowance
        assertEq((user2BalanceAfter - user2BalanceBefore), transferFromAmount);
        assertEq((user1BalanceBefore - transferFromAmount), user1BalanceAfter);    
    }
}