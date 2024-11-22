// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.20;

import {Access} from "../administrator/Access.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

event Swap (address indexed caller, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

contract Pool is Access {
  // 100 000 000  = 6 +  = 20 
  // 100 000 000  = 6 + 6 = 12
  uint256 public k;
  uint256 public precision;


  function init(address _admin) public initializer {
    __Access_init(_admin);
    k = 1e16;
    precision = 6;
  }

  function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) external {
    require(_tokenIn != address(0) && _tokenOut != address(0), "!tokens");
    require(_amountIn > 0, "!amountIn");
    _swap(_tokenIn, _tokenOut, _amountIn);
  }

  function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn) internal {
    uint256 x = (IERC20(_tokenIn).balanceOf(address(this)) * (10 ** precision)) / (10 ** IERC20Metadata(_tokenIn).decimals());
    uint256 y = (IERC20(_tokenOut).balanceOf(address(this))) * (10 ** precision) / (10 ** IERC20Metadata(_tokenOut).decimals());
    
    uint256 dx = _amountIn * (10 ** precision) / (10 ** IERC20Metadata(_tokenIn).decimals());
    uint256 frac = (k * (10 ** (precision * 2))) / (x + dx);
    uint256 dy =  ((y - frac) * ( 10 ** IERC20Metadata(_tokenOut).decimals()))/ (10 ** precision);


    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    IERC20(_tokenOut).transfer(msg.sender, dy);

    emit Swap(msg.sender, _tokenIn, _tokenOut, _amountIn, dy);
  }
} 