// SPDX-License-Identifier: MIT
pragma solidity ^0.15.7;

import "https://github.com/small-blocks/trustcircle/blob/main/contract/interfaces/IBEP20.sol";
import "https://github.com/small-blocks/trustcircle/blob/main/contract/interfaces/ILockFund.sol";
import "https://github.com/small-blocks/trustcircle/blob/main/contract/Context.sol";
import "https://github.com/small-blocks/trustcircle/blob/main/contract/library/Math.sol";

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
  function() external payable {}

  modifier onlyOwner() {
    require(_msgSender() == _owner, "you not owner of this contract");
    _;
  }  

  constructor(uint timeToLock, address tokenAddr, uint256 maxTokenToClaim) public {
    _owner = _msgSender();
    _totalTokenLocked = 0;
    _token = IBEP20(tokenAddr);
    _timeToLock = timeToLock;
    _maximumTokenToClaim = maxTokenToClaim;
  }

  // after call this function, token will just released after locked time
  function lockFund() external onlyOwner {
      require(_lockTime.endTime < now, "the lockout period has not expired");
      _totalTokenLocked = _token.balanceOf(address(this));
      lockFromNow();
  }
  
  function updateLockedTokens() external onlyOwner {
      _totalTokenLocked = _token.balanceOf(address(this));
  }

  function claimUnlock(address beneficiary) external onlyOwner returns(uint256){
    require(_lockTime.endTime < now, "You don't have permission get tokens at time");
    require(_totalTokenLocked > 0, "No token to claim");

    uint256 releasedToken = _token.balanceOf(address(this));
    
    if (releasedToken > _maximumTokenToClaim) {
      releasedToken = _maximumTokenToClaim;
    }

    _totalTokenLocked = _totalTokenLocked.sub(releasedToken); 

    // lock again
    lockFromNow();

    // tranfer to owner address
    address payable receiver = address(uint160(beneficiary));
    
    // tranfer
    _token.transfer(receiver, releasedToken);
    return releasedToken;
  }

  /**
    * @dev lock tokens until preset time
    *
    * Requirements:
    * - time to lock in seconds.
    */
  function lockFromNow() internal {
    _lockTime.startTime = now;
    _lockTime.endTime = _lockTime.startTime + _timeToLock;
  }

  /**
    * @dev get current total locked tokens
    */
  function totalTokenLocked() view external returns(uint256) {
    return _token.balanceOf(address(this));
  }

  /**
    * @dev access to view end lock time, remainning time to lock
    * return {starttime, endtime}
    */
  function lockTime() view external returns(uint, uint) {
    return (_lockTime.startTime, _lockTime.endTime);
  }
}