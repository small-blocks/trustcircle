pragma solidity ^0.6.12;

interface ILiquidityFair {
	/*
	 * Used when migrating to the new LiquidityFair
	 * in case of a contract with newer features.
	 */
	function migrate(address to) external return(bool);
}