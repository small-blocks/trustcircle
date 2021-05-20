pragma solidity ^0.15.7;

interface ILiquidityFair {
	/*
	 * Used when migrating to the new LiquidityFair
	 * in case of a contract with newer features.
	 */
	function migrate(address to) external;
}