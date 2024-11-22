// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";

import {Bridge} from "./Bridge.sol";
import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {Codec, BridgeSendPayload} from "../libs/Codec.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILockBox} from "../core/interface/ILockBox.sol";

/**
 * BridgeLR contract represent the bridge token which handles the type of tokes for Lock & Mint 
 * 
 * On source chain there would exist a lockbox contract which locks and releases the tokens
 * on destination chain token token would be either minted / burned
 */

event SetLockbox(address indexed caller, address indexed token, address indexed lockbox);

contract BridgeLR is Bridge {

    mapping (bytes32 => bool) public processedMessages;
    mapping (address => address) public lockboxes; // mapping token to lockbox
    
    using OptionsBuilder for bytes;
    using SafeERC20 for IERC20;

    constructor(
        address _endpoint,
        address _administrator
    ) OAppCore(_endpoint, msg.sender) Ownable(msg.sender) {
        administrator = _administrator;
    }

    function setLockbox(address _token, address _lockbox) external onlyAdmin {
        require(Common.isContract(_token), "!token");
        require(Common.isContract(_lockbox), "!lockbox");
        lockboxes[_token] = _lockbox;
        emit SetLockbox(msg.sender, _token, _lockbox);
    }

    function send(
        address _srcToken,
        uint32 _dstId,
        address _receiver,
        uint256 _amount,
        uint128 _receiverGas // standard 3200000 units gas works for mint / transfer
    ) external payable notBlacklisted(msg.sender) notBlacklisted(_receiver) notPaused {
        require(_amount > 0, "!amount");
        require(lockboxes[_srcToken] != address(0), "!token !lockbox");
        require(_receiver != address(0), "!receiver");
        require(tokens[_srcToken][_dstId] != address(0), "!destination");
        require(_receiverGas > MIN_RECEIVER_GAS, "!gas");

        bytes memory _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(_receiverGas, 0);
        bytes memory _encodedMessage = abi.encode(
            _dstId,
            _receiver,
            tokens[_srcToken][_dstId],
            _amount,
            Constants.BRIDGE_SEND_HASH
        );

        // Lock the tokens
        IERC20(_srcToken).safeTransferFrom(msg.sender, lockboxes[_srcToken], _amount);
        emit ILockBox.Lock(msg.sender, _srcToken, msg.sender, _amount);

        // Sends the message to the destination endpoint
        _lzSend(
            _dstId,
            _encodedMessage,
            _options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender)
        );
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/, // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/ // Any extra data or options to trigger on receipt.
    ) internal override {

        // Decode the message and mint the tokens
        BridgeSendPayload memory payload = Codec.decodeBridgeSendPayload(message);
        require(payload.amount > 0, "!amount");
        require(lockboxes[payload.token] != address(0), "!token !lockbox");

        bytes32 _hash = keccak256(abi.encode(message, _origin.srcEid, _origin.sender, _origin.nonce));
        require(!processedMessages[_hash], "processed");

        processedMessages[_hash] = true;

        ILockBox(lockboxes[payload.token]).unlock(payload.token, payload.to, payload.amount);
    }
}
