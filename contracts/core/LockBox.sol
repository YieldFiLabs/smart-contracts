// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Access} from "../administrator/Access.sol";
import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";

import {IMinter} from "./interface/IMinter.sol";
import {ILockBox} from "./interface/ILockBox.sol";
import {IYToken} from "./interface/IYToken.sol";

contract LockBox is Access, ILockBox {
    uint256[32] private __gap;

    using SafeERC20 for IERC20;

    function init(address _admin) public initializer {
        __Access_init(_admin);
    }

    function sync(address yToken, uint256 yAmount) external notPaused onlyCollateralManager {
        require(yToken != address(0) && yAmount > 0, "!valid");

        // mint tokens to lock box
        uint256 sAmount = ( yAmount * IYToken(yToken).exchangeRate()) / Constants.PINT;
        IMinter(IERC4626(yToken).asset()).mint(address(this), sAmount);
        IERC20(IERC4626(yToken).asset()).forceApprove(yToken, sAmount);
        IERC4626(yToken).deposit(sAmount, address(this));

        emit Sync(msg.sender, yToken, yAmount, sAmount);
    }

    function unlock(address token, address to, uint256 amount) external nonReentrant notPaused onlyBridge {
        require(to != address(0) && amount > 0, "!valid");
        require(token != address(0) && IERC20(token).balanceOf(address(this)) >= amount, "!balance");

        IERC20(token).safeTransfer(to, amount);

        emit Unlock(msg.sender, token, to, amount);
    }
} 