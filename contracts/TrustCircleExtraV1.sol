// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/ITrustCircleToken.sol";
import "./interfaces/IKeeper.sol";
import "./interfaces/ITrustCircleExtraV1.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./library/SafeMath.sol";

contract TrustCircleExtraV1 is Context, Ownable, ITrustCircleExtraV1 {
	using SafeMath for uint256;

	// userNode info
	struct User {
		bool firstClaim;
		uint256 rewards;
	}

	mapping (address => User) private _users;
	mapping (address => bool) private _admins;
	
	ITrustCircleToken _token;
	uint256 private _maximumClaim;
	uint256 private _minimumClaim;
	uint256 private _denominator;
	bool    private _claimState = true;

	modifier onlyAdmin() {
		require(_admins[_msgSender()], "TrustCircleExtraV1: don't have permission");
		_;
	}

	// fallback function
  	receive() external payable {}

	constructor (address _tokenAdd) public {
		_token = ITrustCircleToken(_tokenAdd);
		_admins[_msgSender()] = true;

  		uint256 decimals = _token.decimals();
  		_maximumClaim =  50 * 10**6 * 10**decimals;
  		_minimumClaim = 10**6 * 10**decimals;
  		_denominator  = 5 * 10**9 * 10**decimals; 
	}

	/*
     * @dev set reward value 
	 */
	function setClaimRewardValues(uint256 _minimum, uint256 _maximum, uint256 _newDenominator) external override onlyOwner() {
		uint256 decimals = _token.decimals();

		_maximumClaim = _maximum * 10**decimals;
		_minimumClaim = _minimum * 10**decimals;
		_denominator  = _newDenominator * 10**decimals;
	}

   /*
	* @dev set zero fee status
	*/
	function setZeroFee(bool enabled) override external onlyOwner() {
		_token.setZeroFee(enabled);
	}

   /*
	* @dev add address to excludes 
	*/
	function addToExcludes(address addr) override external onlyOwner() {
		_token.addToExcludes(addr);
	} 

   /*
	* @dev remove excluded address
	*/
	function removeExcuded(address addr) override external onlyOwner() {
		_token.removeExcuded(addr);
	}

   /*
    * @dev claim reward
	*/
	function claimReward() override external {
		_distributeRewards();
	}

   /*
  	* @dev distribute rewards according to user holdings
	*/
	function _distributeRewards() internal  {
	 	if (!_claimState) {
	 		return;
	 	}

	 	uint256 rewards = _users[_msgSender()].rewards;

	 	if (!_users[_msgSender()].firstClaim) {
		 	uint256 userBalance = _token.balanceOf(_msgSender());
		 	rewards = rewards.add(userBalance.mul(_maximumClaim).div(_denominator));
		 	
		    if (rewards < _minimumClaim) {
	 		    rewards = _minimumClaim;
	 	    }
	 	
		 	_users[_msgSender()].firstClaim = true;
	 	}

	    if (rewards > _token.balanceOf(address(this))) {
	 		rewards = _token.balanceOf(address(this));
	 	}
	 	
	 	require(rewards > 0, "TrustCircleExtra: no rewards to claim");
	 	_users[_msgSender()].rewards = 0;

        // get node information
        (address holder, address previousHoder, address nextHolder, bool isExcluded) = _token.getNodeInfomation (_msgSender());
        
	 	// tranfer tokens to user address
	 	if (!isExcluded) {
	 	    _token.addToExcludes(_msgSender());
	 	    _token.transfer(_msgSender(), rewards);
	 	    _token.removeExcuded(_msgSender());
	 	    return;
	 	}
	 	
	 	_token.transfer(_msgSender(), rewards);
	 }

   /*
  	* @dev set claim reward for address
	*/
	function setRewardForAddress(address addr, uint256 reward) override external onlyAdmin() {
		_users[addr].rewards = _users[addr].rewards.add(reward);
	}

   /*
	* @dev get rewards of address
	*/
	function rewards() override view external returns(uint256) {
	    uint256 totalRewards = _users[_msgSender()].rewards;
	    
	    if (!_users[_msgSender()].firstClaim) {
	        uint256 userBalance = _token.balanceOf(_msgSender());
		 	totalRewards = totalRewards.add(userBalance.mul(_maximumClaim).div(_denominator));
		 	
		 	if (totalRewards < _minimumClaim) {
	 		    totalRewards = _minimumClaim;
	 	    }
	    }
	 
	 	if (totalRewards > _token.balanceOf(address(this))) {
	 		totalRewards = _token.balanceOf(address(this));
	 	}
	    
		return totalRewards;
	}

	/*
     * @dev get back token desposit for charge gas fee
	 */
	function getBackTheChange(uint256 amount) external onlyOwner() {
      	address payable owner = address(uint160(msg.sender));
        owner.transfer(amount);
	}

	/*
	 * @dev on/off claim reward
	 */
	function setClaimState(bool state) override external onlyOwner() {
		_claimState = state;
	}

	/*
     * @dev get all token back
	 */
	function withdrawal() external  onlyOwner() {
		uint256 balance = _token.balanceOf(address(this));
		
		address payable receiver = address(uint160(msg.sender));

	 	// tranfer tokens to user address
	 	_token.transfer(receiver, balance);
	}

   /* 
	* @dev get userInfo
	* use when mirgate
	*/
	function userInfo(address _usersAddr) override view external onlyAdmin() returns(bool, uint256) {
		return (_users[_usersAddr].firstClaim, _users[_usersAddr].rewards);
	}

	function changeOwnerTrustCircleToken(address _usersAddr) external onlyOwner() {
		_token.transferOwnership(_usersAddr);
	}
}