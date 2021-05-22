pragma solidity ^0.6.12;

interface ILockFund {
	/*
	 * @dev lock tokens
	 * after call this function, token will just released after locked time
	 */
	function lockFund() external;


	/* 
	 * @dev update update locked tokens send to this Fund
	 */
	function updateLockedTokens() external;

	/*
	 * @dev return total locked tokens
	 */
	 function totalTokenLocked() view external returns(uint256);

	 /*
	  * @dev return start lock time and end lock time
	  */
	  function lockTime() view external returns(uint,uint);

	  /*
	   * @dev claim to unlock
	   * The amount of released tokens has been installed from scratch and cannot be edite
	   * Released tokens will send to beneficiary address
	   */
	   function claimUnlock(address) external returns(uint256);
}