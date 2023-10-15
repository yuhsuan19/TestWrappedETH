// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WrappedETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}

    function deposit() public payable {
        require(msg.value > 0, "the value to deposit should not be zero");
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint amount) external {
        require(amount > 0, "the amount to withdraw must be greater the zero");
        require(balanceOf(msg.sender) >= amount, "insufficient balance");

        payable(msg.sender).transfer(amount);
        _burn(msg.sender, amount);
    }

    receive() external payable {
        deposit();
    }
}