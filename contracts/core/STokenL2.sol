// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Constants} from "../libs/Constants.sol";
import {IBlackList} from "../administrator/interface/IBlackList.sol";
import {MPC} from "./MPC.sol";
import {IMinter} from "./interface/IMinter.sol";

event Deposit(address indexed caller, address indexed asset, uint256 amount, address indexed receiver, uint256 sAmount);

contract STokenL2 is MPC, ERC20Upgradeable, IMinter {

    uint256[31] __gap;
    
    using SafeERC20 for IERC20;

    function init(
        address _administrator
    ) public initializer {
        __ERC20_init("YieldFi Stable Token", "sUSD");
        __MPC_init(_administrator);
    }

    function mint(address account, uint256 value) external onlyMinterAndRedeemer notPaused {
        _mint(account, value);

        emit Mint(msg.sender, account, value);
    }

    function burn(address account, uint256 value) external onlyMinterAndRedeemer notPaused {
        _burn(account, value);

        emit Burn(msg.sender, account, value);
    }

    function deposit(
        uint256 amount,
        address receiver
    ) public nonReentrant notPaused returns(uint256 sAmount) {
        require(amount > 0  && receiver != address(0), "!valid");
        require(!IBlackList(administrator).isBlackListed(msg.sender), "blacklisted");

        IERC20(usdt).safeTransferFrom(msg.sender, address(this), amount);
        sAmount = (amount * Constants.PINT) / (10 **  IERC20Metadata(usdt).decimals());
        _mint(receiver, sAmount);

        emit Deposit(msg.sender, usdt, amount, receiver, sAmount);
    }
 
    // Hook that is called before any transfer of tokens. This includes minting and burning. Disables transfers from or to blacklisted addresses.
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!IBlackList(administrator).isBlackListed(from) && !IBlackList(administrator).isBlackListed(to), "blacklisted");
        super._update(from, to, value);
    }
}
