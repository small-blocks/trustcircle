// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IBEP20.sol";
import "./interfaces/ILiquidityFair.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./library/SafeMath.sol";
import "./LockFund.sol";

// import Uniswap Interface from github page official 
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol";
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidityFairV01 is Context, Ownable, ILiquidityFair {
	IBEP20 public immutable token1;
	IBEP20 public immutable token2;

	uint256 private _supplyToken1;
	uint256 private _supplyToken2;

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;

	modifier onlyTokenPair(address token1Addr, address token2Addr) {
		require(token1 == token1Addr && token2 == token2Addr, "Pair of tokens not suppoted");
		_;
	}

	constructor(address routerAddr, address token1Addr, address token2Addr) public {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddr);

		// setup token pair
		token1 = IBEP20(token1Addr);
		token2 = IBEP20(token2Addr);
		
		// Create uniswapPair for requested token
		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
					.createPair(token1Addr, token2Addr);

		uniswapV2Router = _uniswapV2Router;
	}

	function deloyLiquidity() external onlyOwner() {
		_supplyToken1 = token1.balanceOf(address(this));
		_supplyToken2 = token2.balanceOf(address(this));

		require(_totalToken1 > 0 && _totalToken2 > 0, "supply must greater than 0");

		
	}

	function currentRate() external returns(uint256) {
		require()
	}
}

