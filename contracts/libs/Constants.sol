// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

library Constants {
    // admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    // role for minting and redeeming tokens
    bytes32 public constant MINTER_AND_REDEEMER_ROLE = keccak256("MINTER_AND_REDEEMER");

    // role for collateral manager who can transfer collateral
    bytes32 public constant COLLATERAL_MANAGER_ROLE = keccak256("COLLATERAL_MANAGER");

    // role for rewarder who can transfer reward 
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER");

    // role for managing blacklist addresses
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    // role for signing transactions
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER");

    // role assigned to bridges
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE");

    uint256 constant PINT = 1e18;
    uint256 constant HUNDRED_PERCENT = 100e18;

    // Period for vesting strategy rewards
    uint256 constant VESTING_PERIOD = 8 hours;

    // max cooling period
    uint256 constant MAX_COOLDOWN_PERIOD = 7 days;

    // min cooling period
    uint256 constant MIN_COOLDOWN_PERIOD = 1 days;

    // ETH Sign Constant
    bytes constant ETH_SIGNED_MESSAGE_PREFIX = "\x19Ethereum Signed Message:\n32";

    // Transaction types
    bytes32 public constant REWARD_HASH = keccak256("REWARD");

    // Bridge transaction types
    bytes32 public constant BRIDGE_SEND_HASH = keccak256("BRIDGE_SEND");
}
