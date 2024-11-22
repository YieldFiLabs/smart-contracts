// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

event MPCUpdate(address indexed caller, address indexed mpc, bool allow);

library Helpers {
    function setAddresses(
        mapping (address => bool) storage addresses,
        address[] calldata data,
        bool allow
    ) internal {
        require(data.length > 0, "!length");
        for (uint8 i = 0; i < data.length;) {
            require(data[i] != address(0), "!address");
            addresses[data[i]] = allow;

            unchecked {
                ++i;
            }

            emit MPCUpdate(msg.sender, data[data.length - 1], allow);
        }        
    }
}