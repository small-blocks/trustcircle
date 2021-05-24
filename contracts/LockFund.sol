// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IBEP20.sol";
import "./interfaces/ILockFund.sol";
import "./library/SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract LockFund is Context, Ownable, ILockFund {
  using SafeMath for uint256;

  struct LockTime {
    uint startTime;
    uint endTime;
  }

  address private _owner;
  uint256 private _totalTokenLocked;
  uint256 private _maximumTokenToClaim;
  IBEP20 private _token;

  LockTime private _lockTime;
  uint private _timeToLock;

  // fallback function
  receive() external payable {}

  constructor(uint timeToLock, address tokenAddr, uint256 maxTokenToClaim) public {
    _owner = _msgSender();
    _totalTokenLocked = 0;
    _token = IBEP20(tokenAddr);
    _timeToLock = timeToLock;
    _maximumTokenToClaim = maxTokenToClaim;
  }

  // after call this function, token will just released after locked time
  function lockFund() external override onlyOwner {
      require(_lockTime.endTime < now, "the lockout period has not expired");
      _totalTokenLocked = _token.balanceOf(address(this));
      _lockFromNow();
  }
  
  function updateLockedTokens() external override onlyOwner {
      _totalTokenLocked = _token.balanceOf(address(this));
  }

  function claimUnlock() external override onlyOwner returns(uint256){
    require(_lockTime.endTime < now, "You do not have permission get tokens at time");
    require(_totalTokenLocked > 0, "No token to claim");

    uint256 releasedToken = _token.balanceOf(address(this));
    
    if (releasedToken > _maximumTokenToClaim) {
      releasedToken = _maximumTokenToClaim;
    }

    _totalTokenLocked = _totalTokenLocked.sub(releasedToken); 

    // lock again
    _lockFromNow();

    // tranfer to owner address
    address payable receiver = address(uint160(msg.sender));
    
    // tranfer
    _token.transfer(receiver, releasedToken);
    return releasedToken;
  }

  /*
   * @dev get back token desposit for charge gas fee
   */
  function getBackTheChange(uint256 amount) external override onlyOwner() {
      address payable owner = address(uint160(msg.sender));
      owner.transfer(amount);
  }

  /**
    * @dev lock tokens until preset time
    *
    * Requirements:
    * - time to lock in seconds.
    */
  function _lockFromNow() internal {
    _lockTime.startTime = now;
    _lockTime.endTime = _lockTime.startTime + _timeToLock;
  }

  /**
    * @dev get current total locked tokens
    */
  function totalTokenLocked() view external override returns(uint256) {
    return _token.balanceOf(address(this));
  }

  /**
    * @dev access to view end lock time, remainning time to lock
    * return {starttime, endtime}
    */
  function lockTime() view external override returns(uint, uint) {
    return (_lockTime.startTime, _lockTime.endTime);
  }
}