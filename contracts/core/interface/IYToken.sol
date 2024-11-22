// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

interface IYToken {
    // functions
    function transferInRewards(uint256 amount, bool profit) external;
    function exchangeRate() external view returns (uint256);

    // events
    event TransferRewards(address indexed caller, uint256 amount);
    event Deposit(address indexed caller, address indexed receiver, address indexed token, uint256 amount, uint256 sAmount, uint256 shares);
}