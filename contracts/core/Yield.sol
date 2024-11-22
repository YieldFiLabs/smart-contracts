// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Access} from "../administrator/Access.sol";
import {Codec, RewardPayload} from "../libs/Codec.sol";
import {Common} from "../libs/Common.sol";
import {Constants} from "../libs/Constants.sol";
import {IRole} from "../administrator/interface/IRole.sol";
import {IMinter} from "./interface/IMinter.sol";
import {IYToken} from "./interface/IYToken.sol";

interface IYield { 
    //events
    event DistributeYield(address indexed asset, address indexed receiver, uint256 amount, bool profit);
}

contract Yield is Access, IYield {
    mapping (bytes32 => bool) public trxns; // transaction hash for duplicate check
    mapping (address => uint256) public epoch; // last epoch till which rewards are distributed
    mapping (address => uint256) public profit; // total rewards disributed
    mapping (address => uint256) public loss; // total loss disributed

    uint256[28] __gap;

    using SafeERC20 for IERC20;

    function init(address _admin) public initializer {
        __Access_init(_admin);
    }

    function validate(bytes32 _hash, bytes memory signature) internal view  {
        address signer = ECDSA.recover(keccak256(abi.encodePacked(Constants.ETH_SIGNED_MESSAGE_PREFIX, _hash)), signature);
        if (!IRole(administrator).hasRole(Constants.SIGNER_ROLE, signer)) {
            revert Common.SignatureVerificationFailed(); 
        }
    }

    function _distributeYield(address receiver, uint256 amount, bool _profit) internal {
        require(receiver != address(0) && amount > 0, "!valid");
        address _sToken = IERC4626(receiver).asset();

        if(_profit) {
            require(IERC20(_sToken).balanceOf(address(this)) >= amount, "!balance");
            IERC20(_sToken).safeTransfer(receiver, amount);
        } else {
            IMinter(_sToken).burn(receiver, amount);
        }
        IYToken(receiver).transferInRewards(amount, _profit);
    }

    function distributeYield(bytes calldata data, bytes memory proofSignature) external notPaused onlyRewarder {
        bytes32 proofHash = keccak256(data);
        require(!trxns[proofHash], "!new txcn");
        validate(proofHash, proofSignature);

        RewardPayload memory payload = Codec.decodeReward(data);

        require(payload.epoch == epoch[payload.receiver] + 1, "!epoch");

        trxns[proofHash] = true;
        epoch[payload.receiver] = payload.epoch;
        
        if (payload.rewardType == 1) { // profit 
             _distributeYield(payload.receiver, payload.amount, true);
            profit[payload.receiver] += payload.amount;
        } else { // loss
            _distributeYield(payload.receiver, payload.amount, false);
            loss[payload.receiver] += payload.amount;
        }

        emit DistributeYield(IERC4626(payload.receiver).asset(), payload.receiver, payload.amount, payload.rewardType == 1);
    }
}