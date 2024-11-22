// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Access} from "../administrator/Access.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMint {
    function mint(address _to, uint256 _amount) external;
}

contract Faucet is Access {
    uint256 private _amount;

    uint256[31] __gap;

    function init(address _admin, uint256 _amt) public initializer {
        __Access_init(_admin);
        _amount = _amt;
    }

    function setAmount(uint256 _newAmount) external onlyAdmin {
        require(_newAmount > 0, "!amount");
        _amount = _newAmount;
    }

    function drip(address _token) external {
        require(IERC20(_token).balanceOf(msg.sender) < (_amount * 10**IERC20Metadata(_token).decimals()), "!balance");
        IMint(_token).mint(msg.sender, _amount * 10**IERC20Metadata(_token).decimals());
    }
}