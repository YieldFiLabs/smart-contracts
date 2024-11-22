// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

interface ISToken {
    struct Withdraw {
        uint256 coolingPeriod;
        uint256 amount;
    }

    // functions

    // events
    event Deposit(address indexed caller, address indexed token, uint256 amount, address indexed receiver, uint256 sAmount);
    event WithdrawRequest(address indexed caller, address indexed receiver, address indexed owner, uint256 sAmount, uint256 amount);
    event Claim(address indexed caller, address indexed receiver, uint256 amount);
}