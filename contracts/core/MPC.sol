// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Access} from "../administrator/Access.sol";
import {Constants} from "../libs/Constants.sol";
import {Helpers} from "../libs/Helpers.sol";

event TransferToMPC(address indexed token, address indexed mpc, uint256 transferAmount);

abstract contract MPC is Access {
    
    address public usdt;
    mapping(address => bool) public mpcs;
    uint8 public decimalsOfAsset;
    
    
    using Helpers for mapping(address => bool);
    using SafeERC20 for IERC20;

    function __MPC_init(
        address _administrator
    ) internal onlyInitializing {
        __Access_init(_administrator);
    }

    function setUSDT(address _usdt) external onlyAdmin {
        require(_usdt != address(0), "!address");
        decimalsOfAsset = IERC20Metadata(_usdt).decimals();
        usdt = _usdt;
    }

    function setMPCs(address[] calldata mpc, bool allow) external onlyAdmin {
        mpcs.setAddresses(mpc, allow);
    }

    function _validateRatios(uint256[] calldata ratios) internal pure {
        uint256 _total = 0;
        for (uint256 i = 0; i < ratios.length;) {
            _total += ratios[i];
            
            unchecked {
                ++i;
            }
        }
        require(_total == Constants.HUNDRED_PERCENT, "!total");
    }

    function _validateMpcs(address[] calldata mpc) internal view {
        require(mpc.length > 0, "!length");
        for (uint256 i = 0; i < mpc.length;) {
            require(mpc[i] != address(0) && mpcs[mpc[i]], "!address");

            unchecked {
                ++i;
            }
        }
    }

    function transferToMPCs(uint256 amount, address[] calldata mpc, uint256[] calldata ratios) external notPaused onlyCollateralManager {
        require(amount > 0, "!valid");
        require(IERC20(usdt).balanceOf(address(this)) >= amount, "!balance");
        require(mpc.length > 0 && mpc.length == ratios.length, "!length");

        _validateRatios(ratios);
        _validateMpcs(mpc);

        for (uint256 i = 0; i < mpc.length; i++) {
            uint256 _transferAmount = (amount * uint256(ratios[i])) / Constants.HUNDRED_PERCENT;
            IERC20(usdt).safeTransfer(mpc[i], _transferAmount);
            emit TransferToMPC(usdt, mpc[i], _transferAmount);
        }
    }

    function rescue(address token, address user, uint256 amount) external onlyAdmin {
        require(token != address(0) &&  token != usdt, "!token");
        require(user != address(0) && amount > 0, "!user !amount");
        IERC20(token).safeTransfer(user, amount);
    }
}
