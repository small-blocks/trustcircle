// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IKeeper {
	/*
     * @dev set reward value 
	 */
	function setClaimRewardValues(uint256 _minimum, uint256 _maximum, uint256 _denominator) external;

	/*
	 *@dev register user information
	 */
	function register(bytes16 pass, bytes16 antiphising) external returns(uint256);

	/*
	 *@dev register user information
	 */
	function update(bytes16 pass, bytes16 newPass, bytes16 antiphising) external returns(bool);

	/*
	 * @dev check this address sender is registered
	 */
	function isRegistered() view external returns(bool);

	/*
	 * @dev return antiphising code
	 */
	function getAntiphising(bytes16 pass) view external returns(bytes16);

	/*
     * @dev get all token back
	 */
	function withdrawal() external;

	/*
     * @dev on/off claim reward
	 */
	function setClaimState(bool state) external;
}