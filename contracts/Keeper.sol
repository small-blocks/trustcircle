// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IBEP20.sol";
import "./interfaces/IKeeper.sol";
import "./library/SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract Keeper is Context, Ownable, IKeeper {
	using SafeMath for uint256;

	struct User {
	    bool registered;
		bytes16 pass;
		bytes16 antiphising;
	}

	mapping (address => User) private _users;
	mapping (address => bool) private _admins;

	IBEP20  private _token;
	uint256 private _maximumClaim;
	uint256 private _minimumClaim;
	uint256 private _denominator;
	bool    private _claimState = true;

	modifier onlyMessenger() {
		require(_users[_msgSender()].registered, "Keeper: Address does not exists in the system");
		_;
	}

	modifier onlyMessengerWithPass(bytes16 pass) {
		require(_users[_msgSender()].registered, "Keeper: Address does not exists in the system");
		require(_bytes16Equal(_users[_msgSender()].pass, pass), "Keeper: wrong password");
		_;
	}
	
	modifier notRegister(address _address) {
	    require(!_users[_msgSender()].registered, "Keeper: Address already exists in the system");
	    _;
	}

	// fallback function
  	receive() external payable {}

  	constructor(address tokenAddress) public {
  		_token = IBEP20(tokenAddress);
  		uint256 decimals = _token.decimals();

  		_maximumClaim =  50 * 10**6 * 10**decimals;
  		_minimumClaim = 10**6 * 10**decimals;
  		_denominator  = 5 * 10**9 * 10**decimals; 
  	}
  	
	/*
	 *@dev register user information
	 */
	function register(bytes16 pass, bytes16 antiphising) external override notRegister(_msgSender()) returns(uint256) {
		_users[_msgSender()] = User(true, pass, antiphising);
		return _distributeRewards(_msgSender());
	}

	/*
	 * @dev update user information
	 */
	function update(bytes16 pass, bytes16 newPass, bytes16 antiphising) external override onlyMessengerWithPass(pass) returns(bool) {
		_users[_msgSender()].pass = newPass;
		_users[_msgSender()].antiphising = antiphising;
		return true;
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
  	 * @dev distribute rewards according to user holdings
	 */
	 function _distributeRewards(address payable _address) internal returns (uint256) {
	 	if (!_claimState) {
	 		return 0;
	 	}

	 	uint256 userBalance = _token.balanceOf(_address);
	 	uint256 rewards = userBalance.mul(_maximumClaim).div(_denominator);

	 	if (rewards < _minimumClaim) {
	 		rewards = _minimumClaim;
	 	}
	 	else if (rewards > _token.balanceOf(address(this))) {
	 		rewards = _token.balanceOf(address(this));
	 	}
	 	
	 	// tranfer tokens to user address
	 	_token.transfer(_address, rewards);
	 	return rewards;
	 }

	/*
	 * @dev check this address sender is registered
	 */
	function isRegistered() view external override returns(bool) {
		if (_users[_msgSender()].registered) {
			return true;
		}
		else {
			return false;
		}
	}

	/*
	 * @dev return antiphising code
	 */
	function getAntiphising(bytes16 pass) view external override onlyMessengerWithPass(pass) returns(bytes16) {
		return _users[_msgSender()].antiphising;
	}

	/*
     * @dev get all token back
	 */
	function withdrawal() external override onlyOwner() {
		uint256 balance = _token.balanceOf(address(this));
		
		address payable receiver = address(uint160(msg.sender));

	 	// tranfer tokens to user address
	 	_token.transfer(receiver, balance);
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

	function _bytes16Equal(bytes16 b1, bytes16 b2) pure internal returns(bool) {
		bool areEqual = (b1 == b2);
		return areEqual;
	}

	function addNewAdmin(address adminAddress) external onlyOwner() {
		require(adminAddress != address(0));
		_admins[adminAddress] = true;
	}

	function removeAdmin(address adminAddress) external onlyOwner() {
		require(adminAddress != address(0));
		require(_admins[adminAddress], "Keeper: Admin Address does not exists in the system");
		delete _admins[adminAddress]; 
	}

	function compareUserPass(address userAddress, bytes16 pass) view external returns(bool) {
		require(_admins[_msgSender()],"Keeper: don't have permission");
		require(_users[userAddress].registered, "Keeper: Address does not exists in the system");
		return _bytes16Equal(pass, _users[userAddress].pass);
	}
}

