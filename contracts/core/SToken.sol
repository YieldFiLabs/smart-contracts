// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {IBlackList} from "../administrator/interface/IBlackList.sol";
import {MPC} from "./MPC.sol";
import {IMinter} from "./interface/IMinter.sol";
import {ISToken} from "./interface/ISToken.sol";
import {IReceipt} from "./interface/IReceipt.sol";


contract SToken is MPC, ERC20Upgradeable, ISToken, IMinter {
    uint256 public coolingPeriod;
    address public withdrawReceipt;

    uint256[30] __gap;

    using SafeERC20 for IERC20;

    function init(
        address _administrator
    ) public initializer {
        __ERC20_init("YieldFi Stable Token", "sUSD");
        __MPC_init(_administrator);
    }

    function setCoolingPeriod(uint256 period) external onlyAdmin {
        require(period >= Constants.MIN_COOLDOWN_PERIOD && period <= Constants.MAX_COOLDOWN_PERIOD, "!period");
        coolingPeriod = period;
    }

    function setWithdrawReceipt(address _withdrawReceipt) external onlyAdmin {
        require(Common.isContract(_withdrawReceipt), "!valid");
        withdrawReceipt = _withdrawReceipt;
    }

    function mint(address account, uint256 value) external onlyMinterAndRedeemer notPaused {
        _mint(account, value);
        emit Mint(msg.sender, account, value);
    }

    function burn(address account, uint256 value) external onlyMinterAndRedeemer notPaused {
        _burn(account, value);
        emit Burn(msg.sender, account, value);
    }

    function _validate(address sender, address receiver, uint256 amount) internal view {
        require(sender != address(0) && receiver != address(0), "!valid");
        require(amount > 0, "!amount");
        require(!IBlackList(administrator).isBlackListed(sender) && !IBlackList(administrator).isBlackListed(receiver), "blacklisted");
    }

    function deposit(
        uint256 amount,
        address receiver
    ) public nonReentrant notPaused  returns(uint256 sAmount) {
        _validate(msg.sender, receiver, amount);

        IERC20(usdt).safeTransferFrom(msg.sender, address(this), amount);
        sAmount = (amount * Constants.PINT) / (10 ** decimalsOfAsset);
        _mint(receiver, sAmount);

        emit Deposit(msg.sender, usdt, amount, receiver, sAmount);
    }

    function withdrawRequest(
        uint256 sAmount,
        address receiver,
        address owner
    ) public nonReentrant notPaused  {
        _validate(owner, receiver, sAmount);
        require(!IBlackList(administrator).isBlackListed(msg.sender), "blacklisted");

        require(balanceOf(owner) >= sAmount, "!amount");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, sAmount);
        }

        _burn(owner, sAmount);
        uint256 amount = (sAmount * (10 ** decimalsOfAsset)) / Constants.PINT;
        IReceipt(withdrawReceipt).mint(receiver, amount, coolingPeriod);

        emit WithdrawRequest(msg.sender, receiver, owner, sAmount, amount);
    }

    // only supports full claim
    function claim(
        uint256 receiptId,
        address receiver
    ) public nonReentrant notPaused  {
        _validate(msg.sender, receiver, receiptId);

        // check ownership of receipt
        require(IERC721(withdrawReceipt).ownerOf(receiptId) == msg.sender, "!owner");
        (uint256 eligibleAt, uint256 amount) = IReceipt(withdrawReceipt).readReceipt(receiptId);
        require(block.timestamp > eligibleAt, "!cooling");

        IReceipt(withdrawReceipt).burn(receiptId);
        IERC20(usdt).safeTransfer(receiver, amount);

        emit Claim(msg.sender, receiver, amount);
    }

    // Hook that is called before any transfer of tokens. This includes minting and burning. Disables transfers from or to blacklisted addresses.
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!IBlackList(administrator).isBlackListed(from) && !IBlackList(administrator).isBlackListed(to), "blacklisted");
        super._update(from, to, value);
    }
}
