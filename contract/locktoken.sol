pragma solidity ^0.5.17;

// SPDX-License-Identifier: Unlicensed
interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal {}

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
}

contract Funding is Context {
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

  // fallback function
  function() external payable {}

  modifier onlyOwner() {
    require(_msgSender() == _owner, "you not owner of this contract");
    _;
  }  

  constructor() public {
    _owner = _msgSender();
    _totalTokenLocked = 0;
    _token = IBEP20(0);
    _maximumTokenToClaim = 50 * 10**6 * 10**4;
  }

  // setup time to lock tokens send to this contract
  // after call this function, token will just released after locked time
  function lockTokens(address tokenAddress) external  onlyOwner {
      require(_lockTime.endTime < now, "the lockout period has not expired");
      _token = IBEP20(tokenAddress);
      _totalTokenLocked = _token.balanceOf(address(this));
      
      // require tranfer amount from owner to this contract 
      //IBEP20 token = IBEP20(tokenAddress);
      //bool result = token.approve(address(this), amount);
      lockFromNow();
  }
  
  function updateTotalTokenLocked() external onlyOwner {
      require(_token != IBEP20(address(0)));
      _totalTokenLocked = _token.balanceOf(address(this));
  }

  function claimTokens() external onlyOwner returns(uint256){
    require(_lockTime.endTime < now, "You don't have permission get tokens at time");
    require(_totalTokenLocked > 0, "No token to claim");
    require(_token != IBEP20(address(0)));

    uint256 releasedToken = _token.balanceOf(address(this));
    
    if (releasedToken > _maximumTokenToClaim) {
      releasedToken = _maximumTokenToClaim;
    }

    _totalTokenLocked = _totalTokenLocked.sub(releasedToken); 

    // lock again
    lockFromNow();

    // tranfer to owner address
    address payable receiver = address(uint160(_msgSender()));
    
    // tranfer
    _token.transfer(receiver, releasedToken);
    return releasedToken;
  }

  function lockFromNow() internal {
      uint256 timeToLock = 60 * 1 seconds;
    _lockTime.startTime = now;
    _lockTime.endTime = _lockTime.startTime + timeToLock;
  }

  // access to view totalTockenLocked
  function totalTokenLocked() view external returns(uint256) {
      require(_token != IBEP20(address(0)));
    return _token.balanceOf(address(this));
  }

  // access to view end lock time, remainning time to lock
  // format: {starttime, endtime}
  function lockTime() view external returns(uint, uint) {
    return (_lockTime.startTime, _lockTime.endTime);
  }
}