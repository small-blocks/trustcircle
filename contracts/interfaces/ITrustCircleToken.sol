// SPDX-License-Identifier: MIT


pragma solidity ^0.6.12;


import "./interfaces/IBEP20.sol";

contract ITrustCircleToken is IBEP20 {
	/*
	* @dev set zero fee status
	*/
	function setZeroFee(bool enabled) external;

	/*
	* @dev add address to excludes 
	*/
	function addToExcludes(address addr) external;

	/*
	* @dev remove excluded address
	*/
	function removeExcuded(address addr) external;

	/*
	* @dev take out the total tokens burned
	*/	
	function totalBurn() view external returns(uint256);

	/*
	* @dev take out the total tokens rewards
	*/
	function totalRewards() view external returns(uint256);

	/*
	* @dev take out the total used rewards
	*/
	function totalUsedReward() view external returns(uint256);

	/**
	* @dev total transaction fees paid by address
	*/	
	function holderTotalFees(address addr) view external returns(uint256);

	/**
	 * @dev total number of rewards received by the address
	 */
	function holderTotalRewards(address addr) view external returns(uint256);
}