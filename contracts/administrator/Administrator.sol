// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Constants} from "../libs/Constants.sol";

import {IBlackList} from "./interface/IBlackList.sol";
import {IPausable} from "./interface/IPausable.sol";
import {IRole} from "./interface/IRole.sol";

/**
 * @dev The contract is used to manage roles, pausable and blacklist.
 * It is inherited by other contracts to manage the roles, pausable and blacklist.
 * ROLES - Admin, Manager, rewarder, minter and redeemer roles.
 */
contract Administrator is IRole, IPausable, IBlackList, Initializable {
    mapping(bytes32 => mapping(address => bool)) private roles;
    mapping(address => bool) private blackList; 
    mapping(address => bool) private paused;
    
    bool private __protoPause;

    uint256[28] __gap;

    function init(address admin) public initializer {
        roles[Constants.ADMIN_ROLE][admin] = true;
    }

    modifier onlyAdmin() {
        require(hasRole(Constants.ADMIN_ROLE, msg.sender), "!admin");
        _;
    }

    modifier onlyManager() {
        require(hasRole(Constants.MANAGER_ROLE, msg.sender), "!manager");
        _;
    }

    /** Function of Roles **/
    function hasRole(
        bytes32 _role,
        address _account
    ) public view override returns (bool) {
        return roles[_role][_account];
    }

    function hasRoles(
        bytes32[] calldata _role,
        address[] calldata _accounts
    ) external view override returns (bool[] memory) {
        require(_role.length == _accounts.length, "!length");
        bool[] memory result = new bool[](_accounts.length);
        for (uint256 i = 0; i < _accounts.length; i++) {
            result[i] = roles[_role[i]][_accounts[i]];
        }
        return result;
    }

    function grantRoles(
        bytes32 _role,
        address[] calldata _accounts
    ) external override onlyAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            roles[_role][_accounts[i]] = true;
            emit RoleGranted(_role, msg.sender, _accounts[i]);
        }
    }

    function revokeRoles(
        bytes32 _role,
        address[] calldata _accounts
    ) external override onlyAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            roles[_role][_accounts[i]] = false;
            emit RoleRevoked(_role, msg.sender, _accounts[i]);
        }
    }

    /** Function of Pausable **/
    function pause() external override onlyAdmin {
        __protoPause = true;
        emit Paused(msg.sender);
    }

    function unpause() external override onlyAdmin {
        __protoPause = false;
        emit Unpaused(msg.sender);
    }

    function pauseSC(address _sc) external override onlyAdmin {
        paused[_sc] = true;
        emit Paused(msg.sender, _sc);
    }

    function unpauseSC(address _sc) external override onlyAdmin {
        paused[_sc] = false;
        emit Unpaused(msg.sender, _sc);
    }

    function isPaused(address _sc) external view override returns (bool) {
        return paused[_sc] || __protoPause;
    }

    /** Function of blacklist  */
    function blackListUsers(
        address[] calldata _evilUsers
    ) external override onlyManager {
        for (uint256 i = 0; i < _evilUsers.length; i++) {
            blackList[_evilUsers[i]] = true;
            emit BlackListed(msg.sender, _evilUsers[i]);
        }
    }

    function removeBlackListUsers(
        address[] calldata _clearedUsers
    ) external override onlyManager {
        for (uint256 i = 0; i < _clearedUsers.length; i++) {
            blackList[_clearedUsers[i]] = false;
            emit BlackListCleared(msg.sender, _clearedUsers[i]);
        }
    }

    function isBlackListed(address _user) external view override returns (bool) {
        return blackList[_user];
    }
}
