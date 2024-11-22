// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

interface IReceipt {
  function mint(address _to, uint256 _amount, uint256 _coolingPeriod) external;
  function burn(uint256 _tokenId) external;
  function readReceipt(uint256 _tokenId) external view returns (uint256 eligibleAt, uint256 amount);
}