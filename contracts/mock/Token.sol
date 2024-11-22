// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Access} from "../administrator/Access.sol";

import {IMinter} from "../core/interface/IMinter.sol";

contract Token is ERC20Upgradeable, IMinter, Access {
    uint8 public decim;

    function init(
        string memory name,
        string memory symbol,
        uint8 _decimals,
        address _administrator
    ) public initializer {
        __ERC20_init(name, symbol);
        __Access_init(_administrator);
        decim = _decimals;
    }

    function mint(address _to, uint256 _amount) external override {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external override {
        _burn(_from, _amount);
    }

    function decimals() public override view returns (uint8) {
        return decim;
    }
} 