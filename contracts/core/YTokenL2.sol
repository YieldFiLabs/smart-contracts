// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Access} from "../administrator/Access.sol";
import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {IBlackList} from "../administrator/interface/IBlackList.sol";
import {IMinter} from "./interface/IMinter.sol";

interface IOracle {
    function getPrice(address yToken) external view returns (uint256);
}

interface ISTokenL2 {
    function usdt() external returns(address);
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}

event SetOracle(address indexed caller, address indexed oracle);
event SetSToken(address indexed caller, address indexed sToken);
event Deposit(address indexed caller, address indexed asset, uint256 amount, address indexed receiver, uint256 yAmount);
event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 amount, uint256 yAmount);
event SyncResults(address indexed caller, uint256 totalSupply, uint256 oldBalance, uint256 change, bool gain);

struct Sync {
    uint256 lastSyncAmount;
    uint256 changeFromLastSync;
    bool gain;
}

contract YTokenL2 is Access, ERC20Upgradeable, IMinter {
    address public oracle;
    address public sToken;
    Sync public sync;

    uint256[28] __gap;

    using SafeERC20 for IERC20;

    function init(
        address _administrator,
        address _oracle,
        address _sToken
    ) public initializer {
        require(_administrator != address(0) && Common.isContract(_oracle) && Common.isContract(_sToken), "!valid");
        __ERC20_init("YieldFi yToken", "yUSD");
        __Access_init(_administrator);
        oracle = _oracle;
        sToken = _sToken;
    }

    function setOracle(address _oracle) public onlyAdmin {
        require(Common.isContract(_oracle), "!oracle");
        oracle = _oracle;
        emit SetOracle(msg.sender, oracle);
    }

    function setSToken(address _sToken) public onlyAdmin {
        require(Common.isContract(_sToken), "!sToken");
        sToken = _sToken;
        emit SetSToken(msg.sender, sToken);
    }

    function syncYToken() public onlyRewarder returns(Sync memory) {
        uint256 oldBalance = sync.lastSyncAmount;

        if(totalSupply() >= oldBalance) {
            sync.changeFromLastSync = totalSupply() - oldBalance;
            sync.gain = true;
        } else {
            sync.changeFromLastSync = oldBalance - totalSupply();
            sync.gain = false;
        }

        sync.lastSyncAmount = totalSupply();
        emit SyncResults(msg.sender, totalSupply(), oldBalance, sync.changeFromLastSync, sync.gain);
        return (sync);
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
        address token, // USDT or sToken
        uint256 amount,
        address receiver
    ) public nonReentrant notPaused notBlacklisted(msg.sender) returns(uint256 shares) {
        require(token != address(0) && amount > 0 && receiver != address(0), "!valid");
        require(token == ISTokenL2(sToken).usdt() || token == sToken, "!token");
        require(IERC20(token).balanceOf(msg.sender) >= amount, "!amount");

        uint256 sAmount;

        if(token == ISTokenL2(sToken).usdt()) {
            IERC20(token).safeTransferFrom(msg.sender, sToken, amount);
            sAmount = (amount * Constants.PINT) / (10 ** IERC20Metadata(token).decimals());
        } else if (token == sToken) {
            ISTokenL2(sToken).burn(msg.sender, amount);
            sAmount = amount;
        }

        uint256 _price = IOracle(oracle).getPrice(address(this));
        require(_price > 0, "!price");

        shares = (sAmount * Constants.PINT) / _price ;
        _mint(receiver, shares);

        emit Deposit(msg.sender, token, amount, receiver, shares);
    }

    function withdraw(
        uint256 shares,
        address receiver,
        address owner
    ) public nonReentrant notPaused notBlacklisted(msg.sender) returns(uint256 sAmount) {
        require(shares > 0 && receiver != address(0) && owner != address(0), "!valid");
        require(balanceOf(owner) >= shares, "!shares");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        uint256 _price = IOracle(oracle).getPrice(address(this));
        sAmount = (shares * _price) / Constants.PINT;

        _burn(owner, shares);
        ISTokenL2(sToken).mint(receiver, sAmount);

        emit Withdraw(msg.sender, receiver, owner, shares, sAmount);
    }

    // Hook that is called before any transfer of tokens. This includes minting and burning. Disables transfers from or to blacklisted addresses.
    function _update(address from, address to, uint256 value) internal virtual override {
        require(!IBlackList(administrator).isBlackListed(from) && !IBlackList(administrator).isBlackListed(to), "blacklisted");
        super._update(from, to, value);
    }

    function rescue(address _token, address _user, uint256 _amount) external onlyAdmin {
        require(_token != address(0) && _token != sToken, "!token");
        require(_user != address(0) && _amount > 0, "!user !amount");
        IERC20(_token).safeTransfer(_user, _amount);
    }
}
