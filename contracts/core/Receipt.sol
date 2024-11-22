// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {Access} from "../administrator/Access.sol";
import {Common} from "../libs/Common.sol";
import {IReceipt} from "./interface/IReceipt.sol";

struct ReceiptData {
  uint256 eligibleAt;
  uint256 amount;
}

contract Receipt is ERC721EnumerableUpgradeable, Access, IReceipt {
    address public sToken;
    uint256 public counter; // a counter for computing unique token id
    mapping(uint256 => ReceiptData) public receipts;

    uint256[29] __gap;

    modifier onlySToken() {
        require(msg.sender == sToken, "!sToken");
        _;
    }

    function setSToken(address _sToken) public onlyAdmin {
        require(Common.isContract(_sToken), "!sToken");
        sToken = _sToken;
    }

    function init(address _admin) public initializer {
        __Access_init(_admin);
        __ERC721_init("YieldFi Withdrawal Receipt", "yWDR");
        counter = 0;
    }

    // validations are already done at the caller side
    function mint(
        address _to,
        uint256 _amount,
        uint256 _coolingPeriod
    ) external notPaused onlySToken { 
        require(_amount > 0 && _coolingPeriod > 0, "!valid");
        uint256 tokenId = counter + 1;
        
        _mint(_to, tokenId);
        counter += 1; // increment the id counter

        receipts[tokenId] = ReceiptData({
            eligibleAt: block.timestamp + _coolingPeriod,
            amount: _amount
        });
    }

    function readReceipt(
        uint256 _tokenId
    ) public view returns (uint256 eligibleAt, uint256 amount) {
        return (receipts[_tokenId].eligibleAt, receipts[_tokenId].amount);
    }

    function burn(uint256 _tokenId) external onlySToken notPaused {
        _burn(_tokenId);
        delete receipts[_tokenId];
    }
}