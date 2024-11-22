// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {OAppSender, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {OAppReceiver, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {Codec, BridgeSendPayload} from "../libs/Codec.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBlackList} from "../administrator/interface/IBlackList.sol";
import {ILockBox} from "../core/interface/ILockBox.sol";
import {IPausable} from "../administrator/interface/IPausable.sol";
import {IMinter} from "../core/interface/IMinter.sol";
import {IRole} from "../administrator/interface/IRole.sol";

event SetToken(address indexed caller, uint32 indexed dstId, address indexed token);
event SetAdministrator(address indexed caller, address indexed administrator);

abstract contract Bridge is OAppSender, OAppReceiver {
    address public administrator;
    uint256 public MIN_RECEIVER_GAS = 21000;

    using OptionsBuilder for bytes;
    mapping (address => mapping (uint32 => address)) public tokens; // mapping for destination id to token

    modifier onlyAdmin() {
        require(
            IRole(administrator).hasRole(Constants.ADMIN_ROLE, msg.sender),
            "!admin"
        );
        _;
    }

    modifier notBlacklisted(address user) {
        require(!IBlackList(administrator).isBlackListed(user), "blacklisted");
        _;
    }

    modifier notPaused() {
        require(!IPausable(administrator).isPaused(address(this)), "paused");
        _;
    }

    function setMIN_RECEIVER_GAS(uint256 _MIN_RECEIVER_GAS) external onlyAdmin {
        require(_MIN_RECEIVER_GAS > 21000, "!MIN_RECEIVER_GAS");
        MIN_RECEIVER_GAS = _MIN_RECEIVER_GAS;
    }

    function oAppVersion()
        public
        pure
        override(OAppReceiver, OAppSender)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }

    function setAdministrator(address _administrator) external onlyAdmin {
        require(Common.isContract(_administrator), "!address");
        administrator = _administrator;
        emit SetAdministrator(msg.sender, _administrator);
    }

    function quote(
        uint32 _dstEid,
        bytes memory _payload,
        bool _payInLzToken,
        uint128 _receiverGas
    ) public view returns (MessagingFee memory fee) {
        require(_receiverGas > MIN_RECEIVER_GAS, "!gas");
        bytes memory _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(_receiverGas, 0);
        fee = _quote(_dstEid, _payload, _options, _payInLzToken);
    }

    function setTokens(address _srcToken, uint32 [] calldata _dstIds, address [] calldata _tokens) external onlyAdmin {
        require(_srcToken != address(0), '!src token');
        require(_dstIds.length == _tokens.length, "!length");
        for (uint256 i = 0; i < _dstIds.length;) {
            require(_tokens[i] != address(0), "!token");
            tokens[_srcToken][_dstIds[i]] = _tokens[i];
            emit SetToken(msg.sender, _dstIds[i], _tokens[i]);

            unchecked {
                ++i;
            }
        }
    }
}