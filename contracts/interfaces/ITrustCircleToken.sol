// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITrustCircleExtraV1 {
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
	 * @dev claim reward
	 */
	function claimReward() external;

	/*
	 * @dev on/off claim reward
	 */
	function setClaimState(bool state) external;
	
    /*
     * @dev set reward value 
	 */
	function setClaimRewardValues(uint256 _minimum, uint256 _maximum, uint256 _newDenominator) external;

	/*
  	 * @dev set claim reward for address
	 */
	 function setRewardForAddress(address addr, uint256 reward) external;

	/*
	 * @dev get rewards of addres
	 */
	 function rewards() view external returns(uint256);

	/* 
	 * @dev get userInfo
	 * use when mirgate
	 */
	 function userInfo(address _usersAddr) view external returns(bool, uint256);
}