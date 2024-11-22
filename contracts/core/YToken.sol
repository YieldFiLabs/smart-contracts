// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Access} from "../administrator/Access.sol";
import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {IBlackList} from "../administrator/interface/IBlackList.sol";
import {IMinter} from "./interface/IMinter.sol";
import {IYToken} from "./interface/IYToken.sol";

interface ISToken {
    function usdt() external returns(address);
}

event Rescue(address indexed caller, address indexed token, address indexed to, uint256 amount);

contract YToken is Access, IYToken, ERC4626Upgradeable {
    uint256 public totAssets;
    uint256 public vestingAmount;
    uint256 public lastDistributionTimestamp;
    address public yield;

    uint256[28] __gap;

    using SafeERC20 for IERC20;

    function init(
        address _administrator,
        address sToken,
        address _yield
    ) public initializer {
        __Access_init(_administrator);
        __ERC20_init("YieldFi yToken", "yUSD");
        __ERC4626_init(IERC20(sToken));
        yield = _yield;
    }

    function setYield(address _yield) external onlyAdmin {
        require(Common.isContract(_yield), "!yield");
        yield = _yield;
    }

    function transferInRewards(uint256 amount, bool profit) external nonReentrant notPaused {
        require(msg.sender == yield, "!yield");
        require(amount > 0, "!amount");

        if (!profit) {
            _updateTotalAssets(amount, false);
            return;
        }

        _updateVestingAmount(amount);
        emit TransferRewards(msg.sender, amount);
    }

    function _updateVestingAmount(uint256 newVestingAmount) internal {
        require(getUnvestedAmount() == 0, "!vesting");

        vestingAmount = newVestingAmount; 

        _updateTotalAssets(newVestingAmount, true);
        lastDistributionTimestamp = block.timestamp;
    }

    function totalAssets() public view override returns (uint256) {
        return totAssets - getUnvestedAmount(); // chk: Can there be case of underflow ?
    }

    function getUnvestedAmount() public view returns (uint256) {
        uint256 timeSinceLastDistribution = block.timestamp - lastDistributionTimestamp;

        if (timeSinceLastDistribution >= Constants.VESTING_PERIOD) {
            return 0;
        }

        return ((Constants.VESTING_PERIOD - timeSinceLastDistribution) * vestingAmount) / Constants.VESTING_PERIOD;
    }

    function _updateTotalAssets(uint256 _amount, bool _add) internal {
        totAssets = _add ? totAssets + _amount : totAssets - _amount;
    }

    function exchangeRate() external view returns(uint256) {
        return previewMint(Constants.PINT);
    }

    function depositUSDT(
        address usdt,
        uint256 amount,
        address receiver
    ) public nonReentrant notPaused  returns(uint256 shares) {
        require(amount > 0  && receiver != address(0) && usdt != address(0), "!valid");
        require(!IBlackList(administrator).isBlackListed(msg.sender), "blacklisted");
        require(!IBlackList(administrator).isBlackListed(receiver), "blacklisted");
        require(ISToken(asset()).usdt() == usdt, "!usdt");

        IERC20(usdt).safeTransferFrom(msg.sender, asset(), amount);
        uint256 sAmount = (amount * Constants.PINT) / (10 **  IERC20Metadata(usdt).decimals());

        IMinter(asset()).mint(address(this), sAmount);

        shares = convertToShares(sAmount);
        _updateTotalAssets(sAmount, true);

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, sAmount, shares);
    }

    function _deposit(
        address caller, 
        address receiver, 
        uint256 assets, 
        uint256 shares
    ) internal override nonReentrant notPaused {
        require(receiver != address(0) && assets > 0 && shares > 0, "!valid");
        require(!IBlackList(administrator).isBlackListed(caller), "blacklisted");
        super._deposit(caller, receiver, assets, shares);
        _updateTotalAssets(assets, true);
    }

    function _withdraw(
        address caller, 
        address receiver, 
        address owner, 
        uint256 assets, 
        uint256 shares
    ) internal override nonReentrant notPaused {
        require(receiver != address(0) && owner != address(0) && assets > 0 && shares > 0, "!valid");
        require(!IBlackList(administrator).isBlackListed(caller) && !IBlackList(administrator).isBlackListed(receiver), "blacklisted");
        super._withdraw(caller, receiver, owner, assets, shares);
        _updateTotalAssets(assets, false);
    }

    // Hook that is called before any transfer of tokens. This includes minting and burning. Disables transfers from or to blacklisted addresses.
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!IBlackList(administrator).isBlackListed(from) && !IBlackList(administrator).isBlackListed(to), "blacklisted");
        super._update(from, to, value);
    }

    function rescue(address _token, address _user, uint256 _amount) external onlyAdmin {
        require(_token != address(0) && _token != asset(), "!token");
        require(_user != address(0) && _amount > 0, "!user !amount");
        IERC20(_token).safeTransfer(_user, _amount);
        emit Rescue(msg.sender, _token, _user, _amount);
    }
}
