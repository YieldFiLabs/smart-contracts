// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

interface IMinter {
    //functions
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;

    //events
    event Mint(address indexed _minter, address indexed _to, uint256 _amount);
    event Burn(address indexed _minter, address indexed _from, uint256 _amount);
}