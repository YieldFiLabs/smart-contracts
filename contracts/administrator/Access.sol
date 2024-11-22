// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";

import {IBlackList} from "./interface/IBlackList.sol";
import {IPausable} from "./interface/IPausable.sol";
import {IRole} from "./interface/IRole.sol";

event SetAdministrator(address indexed caller, address indexed administrator);

// To define all the access modifiers
abstract contract Access is ReentrancyGuardUpgradeable {
    address public administrator;

    function __Access_init(address _administrator) internal onlyInitializing {
        __ReentrancyGuard_init();
        require(_administrator != address(0), "!administrator");
        administrator = _administrator;
    }

    modifier onlyAdmin() {
        require(
            IRole(administrator).hasRole(Constants.ADMIN_ROLE, msg.sender),
            "!admin"
        );
        _;
    }

    modifier onlyCollateralManager() {
        require(
            IRole(administrator).hasRole(
                Constants.COLLATERAL_MANAGER_ROLE,
                msg.sender
            ),
            "!cmgr"
        );
        _;
    }

    modifier onlyBridge() {
        require(
            IRole(administrator).hasRole(Constants.BRIDGE_ROLE, msg.sender),
            "!bridge"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IRole(administrator).hasRole(Constants.MANAGER_ROLE, msg.sender),
            "!manager"
        );
        _;
    }

    modifier onlyMinterAndRedeemer() {
        require(IRole(administrator).hasRole(Constants.MINTER_AND_REDEEMER_ROLE, msg.sender),
            "!minter"
        );
        _;
    }

    modifier onlyRewarder() {
        require(
            IRole(administrator).hasRole(Constants.REWARDER_ROLE, msg.sender),
            "!rewarder"
        );
        _;
    }

    modifier notPaused() {
        require(!IPausable(administrator).isPaused(address(this)), "paused");
        _;
    }

    modifier notBlacklisted(address user) {
        require(!IBlackList(administrator).isBlackListed(user), "blacklisted");
        _;
    }

    function setAdministrator(address _administrator) external onlyAdmin {
        require(Common.isContract(_administrator), "!contract");
        administrator = _administrator;
        emit SetAdministrator(msg.sender, administrator);
    }
}
