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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMinter} from "../core/interface/IMinter.sol";
import {IRole} from "../administrator/interface/IRole.sol";

/**
 * BridgeMB contract represent the bridge token which handles the type of tokes for Mint & Burn
 */

contract BridgeMB is Bridge {
    using OptionsBuilder for bytes;

    mapping (bytes32 => bool) public processedMessages;

    constructor(
        address _endpoint,
        address _administrator
    ) OAppCore(_endpoint, msg.sender) Ownable(msg.sender) {
        administrator = _administrator;
    }

    function send(
        address _srcToken,
        uint32 _dstId,
        address _receiver,
        uint256 _amount,
        uint128 _receiverGas // standard 3200000 units gas works for mint / transfer
    ) external payable notBlacklisted(msg.sender) notBlacklisted(_receiver) notPaused {
        require(_amount > 0, "!amount");
        require(tokens[_srcToken][_dstId] != address(0), "!desToken");
        require(_receiver != address(0), "!receiver");
        require(_receiverGas > MIN_RECEIVER_GAS, "!gas");
      
        IMinter(_srcToken).burn(msg.sender, _amount);

        bytes memory _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(_receiverGas, 0);

        bytes memory _encodedMessage = abi.encode(
            _dstId,
            _receiver,
            tokens[_srcToken][_dstId],
            _amount,
            Constants.BRIDGE_SEND_HASH
        );

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

        require(Common.isContract(payload.token), "!token");
        require(payload.amount > 0, "!amount");

        bytes32 _hash = keccak256(abi.encode(message, _origin.srcEid, _origin.sender, _origin.nonce));
        require(!processedMessages[_hash], "processed");

        processedMessages[_hash] = true;

        IMinter(payload.token).mint(payload.to, payload.amount);
    }
}
