// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./library/SafeMath.sol";

contract TrustCircleToken is Context, IBEP20, Ownable {
  // Used for linkedlist mechanism
  struct HolderNode {
    address holder;
    address nextHolder;
    address previousHoder;
  }

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => uint256) private _holdersTotalFees; // keep the total transaction fees paid by an address
  mapping (address => uint256) private _holderTotalReceived; // keep the total number of rewards received by the address
  mapping (address => HolderNode) private _holders;
  mapping (address => bool) private _excludes;

  string  private _symbol = "TRUST CIRCLE";
  string  private _name = "TRCI";
  uint8   private _decimals = 16;
  uint256 private _totalSupply = 10**15 * 10**16;

  uint public immutable _burnRate = 2; // burn 3%
  uint public immutable _rewardRate = 3; // reward is 3%

  // total current bonus tokens
  uint256 private _totalReward = 0;

  // total current burn tokens
  uint256 private _burnTotal = 0;

  uint256 private _maximumBurnTotal = 5 * 10**14 * 10**16;
  uint256 private _minimumRequirementToReceiveReward = 10**9 * 10**16;
  uint256 private _maxTransactionAmount = 10**9 * 10**16;
  uint256 private _maxAmountForEachHolderAddress = 5 * 10**9 * 10**16;

  bool    private _zeroFeeEnabled = false;

  address private _headNode;
  address private _tailNode;
  address private _nextNodeReceiveReward;

  event NewHolder(address indexed newHolder);
  event NewLoser(address indexed newLoser);

  modifier limitRecipienAmount(address recipient, uint256 amount) {
    require(recipient != address(0), "BEP20: transfer to the zero address");

    if (!_excludes[recipient]) {
      balance = _balances[recipient];
      require(balance.add(amount) <= _maxAmountForEachHolderAddress, "BEP20: the amount sent exceeds the balance of the receiving account");
    }
    _;
  }

  modifier maxTransactionAmount(address sender, address recipient, uint25 amount) {
    if (!_excludes[sender] || !_excludes[recipient]) {
      require(amount <= _maxTransactionAmount, "BEP20: you send an amount in excess of the allowed amount is 5000000");
    }
    _;
  }

  constructor() public {
    _balances[msg.sender] = _totalSupply;

    HolderNode holder = new HolderNode(msg.sender, address(0), address(0));

    // init root node , head and tail node
    _holders[msg.sender] = holder;
    _headNode = msg.sender;
    _tailNode = msg.sender;
    _nextNodeReceiveReward = msg.sender;

    // add to excluded
    _excludes[msg.sender] = true;
    _excludes[address(this)] = true;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal limitRecipienAmount(recipient, amount) maxTransactionAmount(sender, recipient, amount) {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    uint256 burnAmount = 0;
    uint256 rewardAmount = 0;

    if (!_excludes[sender]) {
      burnAmount = _getBurnAmount(amount);
      rewardAmount = _getRewardAmount(amount);
    }

    uint256 tranferFee = burnAmount.add(rewardAmount);
    _balances[sender] = _balances[sender].sub(tranferFee, "BEP20: transfer fee exceeds balance");
      .sub(amount, "BEP20: transfer amount exceeds balance");

    _balances[recipient] = _balances[recipient].add(amount);
    
    _burn(burnAmount);
    _holdersTotalFees[sender] = _holders[sender].add(tranferFee);

    // fetch infor of sender and recipient
    _fetchNode(sender);
    _fetchNode(recipient);

    _distributeReward(rewardAmount);

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * ------------------------------------------------------------------
   * EXTRA FEATURES TO MAKE THIS TOKEN BECOME AMAZING
   * ------------------------------------------------------------------
   */

   /*
    * @dev get amount of token will be used to burn from tranfer amount
    * burn amount will be zero if total amount of tokens is meet maximum
    */
   function _getBurnAmount(uint256 transferAmount) internal returns(uint256) {
      // burn amount
      uint256 burnAmount = 0;

      if (_burnTotal < _maximumBurnTotal) {
        burnAmount = transferAmount.mul(_burnRate).div(100);

        // Maximum amount of tokens to burn
        uint256 maximumBurnAllowed = _maximumBurnTotal.sub(_burnTotal);
        if (maximumBurnAllowed < burnAmount) {
            burnAmount = maximumBurnAllowed;
        }
      }

      return burnAmount;
   }

   /**
    * @dev Get amount of token will be used to add to reward pool
    * reward value will be zero if zeroFeeEnabled is True
    */
   function _getRewardAmount(uint256 transferAmount) internal returns(uint256) {
      if (_zeroFeeEnabled) {
        return 0;
      }

      uint256 rewardAmount = transferAmount.mul(_rewardRate).div(100);
      return rewardAmount;
   }

   /**
    * @dev burn by send to dead address
    * return amount of token burned
    */
   function _burn(uint256 burnAmount) internal {
      if (burnAmount <= 0) {
        return;
      }

      _burnTotal = _burnTotal.add(burnAmount);
   }

   /**
    * @dev Proceed to distribute the reward
    * The reward is distributed in a circle,
    * Next reward recipient will receive proportionally 
    * To the number of tokens they are holding.
    * Required minimum amount is 5 milions to receive Bonus
    * Those who do not meet the requirements will be disqualified from the Circle Reward pool
    */
   function _distributeReward(uint256 amount) internal {
      _totalReward = _totalReward.add(amount);

      // Stop the reward distribution if the account is excluded 
      // Or the total reward remaining is less than 3000
      if ((_excludes[_nextNodeReceiveReward] && _nextNodeReceiveReward != owner()) || _totalReward < 10**3 * 10**16) {
        return 0;
      }

      // reinstall the reward node if something goes wrong 
      if(!_holders[_nextNodeReceiveReward]) {
        _nextNodeReceiveReward = _headNode;
        return 0;
      }

      // Check bonus conditions 
      // And remove from the bonus round if not meeting the requirements:
      //    balance is meet minimum requirement
      if (_balances[_nextNodeReceiveReward] < _minimumRequirementToReceiveReward) {
        _removeNode(_nextNodeReceiveReward);
        return 0;
      }


      // calculate reward for this holder
      // rewardsWillReceived = (balance_of_hodler * 3% * _totalReward) / totalSuppy
      uint256 rewardsWillReceived = _balances[_nextNodeReceiveReward].mul(_totalReward).mul(3).div(100).div(totalSuppy);

      // update remaining reward
      _totalReward = _totalReward.sub(rewardsWillReceived);

      // give reward !
      _balances[_nextNodeReceiveReward] = _balances[_nextNodeReceiveReward].add(rewardsWillReceived);
      _holderTotalReceived[_nextNodeReceiveReward] = _holderTotalReceived[_nextNodeReceiveReward].add(rewardsWillReceived);

      // move to next node
      if (_nextNodeReceiveReward == _tailNode) {
        _nextNodeReceiveReward = _headNode;
      }
      else {
        _nextNodeReceiveReward = _holders[_nextNodeReceiveReward].nextHolder;
      }
   }

   /**
    * @dev get holder by address
    */
    function _getHolder(address holderAddr) internal returns(HolderNode) {
      return _holders[holderAddr];
    }

   /**
    * @dev total transaction fees paid by address
    */
    function holderTotalFees(address addr) view external returns(uint256) {
      return _holdersTotalFees[addr];
    }

    /**
     * @dev total number of rewards received by the address
     */
     function holderTotalRewards(address addr) view external returns(uint256) {
      return _holderTotalReceived[addr];
     }


   /**
    * @dev fetch information of holder node
    */
    function _fetchNode(address holderAddr) internal {
      if (_excludes[holderAddr] && holderAddr != owner() || 
        _balances[holderAddr] < _minimumRequirementToReceiveReward) {
        _removeNode(holderAddr);
      }

    }

  /**
   * @dev Add new owner if the current address is not ever transaction before
   * just update recipient, because this address alway have tokens to received reward
   * update excluded value
   */
   function _addNewNode(address holderAddr) internal {
      if (_excludes[holderAddr]) {
        return;
      }

      HolderNode newNode = new HolderNode(holderAddr, address(0), address(0));

      newNode.previousHoder = _tailNode;
      _holders[_tailNode].nextHolder = holderAddr;
      _holders[holderAddr] = newNode;
      _tailNode = holderAddr;

      emit NewHolder(holder);
   }

   /**
    * @dev get Holder Node information
    */
   function getNodeInfomation (address addr) external returns(
      address holder, 
      address nextHolder, 
      address previousHoder,
      bool isExcluded) {
      require(!_holders[addr]);
      HolderNode holderNode = _holders[addr];
      return (holderNode.holder, holderNode.previousHoder, holder.nextHolder, _excludes[holder]);
   }

   /**
    * @dev fetch node
    * remove node if not meet requirement condition
    * Add node if meet requirement condition
    */
    function _fetchNode(address holderAddr) internal {
      if (holderAddr == _headNode) {
        return;
      }

      if(_balances[holderAddr] < _minimumRequirementToReceiveReward) {
          _removeNode(holderAddr);
      }
      else if(!_holders[holderAddr]) {
          _addNewNode(holderAddr);
      }
    }

   /**
    * @dev remove node
    */
    function _removeNode(address loser) {
      if (!_holders[loser]) {
        return;
      }

      address pAddr = _holders[loser].previousHolder;

      bool isNextReceiveReward = false;
      if (loser == _nextNodeReceiveReward) {
        isNextReceiveReward = true;
      }
      
      // if end node is same with tail node,
      // set tail node to previous node 
      if (loser == _tailNode) {
          _holder[pAddr].nextHolder = address(0);
          _tailNode = pAddr;

          // move _nextNodeReceiveReward to head node
          if (isNextReceiveReward) {
            _nextNodeReceiveReward = _headNode;
          }
      }
      // if is middle node, then setup both previous and next node
      else {
          nAddr = _holders[loser].nextHolder;
          _holder[pAddr].nextHolder = nAddr;
          _holder[nAddr].previousHoder = pAddr;

          // move _nextNodeReceiveReward to next node
          if (isNextReceiveReward) {
            _nextNodeReceiveReward = nAddr;
          }
      }

      // remove node
      _holders[loser] = 0;
    }
}