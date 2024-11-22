// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Access} from "../administrator/Access.sol";

contract Oracle is Access {
    mapping (address => uint256) public prices;

    function init(address _admin) public initializer {
        __Access_init(_admin);
    }

    function setPrice(address _token, uint256 _price) external {
        prices[_token] = _price;
    }

    function getPrice(address _token) external view returns (uint256) {
        return prices[_token];
    }
}