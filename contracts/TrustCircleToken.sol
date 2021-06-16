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

  string  private _name = "TRUST CIRCLE";
  string  private _symbol = "TRCI";
  uint8   private _decimals = 16;
  uint256 private _totalSupply = 10**15 * 10**16;

  uint public immutable _burnRate = 2; // burn 3%
  uint public immutable _rewardRate = 3; // reward is 3%

  // total current tokens will be use for give reward
  uint256 private _totalRewards = 0;

  // used rewards
  uint256 private _usedRewards = 0;

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
      require(_balances[recipient].add(amount) <= _maxAmountForEachHolderAddress, "BEP20: the amount sent exceeds the balance of the receiving account");
    }
    _;
  }

  modifier maxTransactionAmount(address sender, address recipient, uint256 amount) {
    if (!_excludes[sender] || !_excludes[recipient]) {
      require(amount <= _maxTransactionAmount, "BEP20: you send an amount in excess of the allowed amount is 1000000000");
    }
    _;
  }

  constructor() public {
    _balances[msg.sender] = _totalSupply;

    _holders[msg.sender] = HolderNode(msg.sender, address(0), address(0));

    // init root node , head and tail node
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
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view override returns (uint256) {
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
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
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
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
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
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    _balances[recipient] = _balances[recipient].add(amount);
    
    _burn(sender, burnAmount);
    _holdersTotalFees[sender] = _holdersTotalFees[sender].add(tranferFee);

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
   function _getBurnAmount(uint256 transferAmount) view internal returns(uint256) {
      if (_zeroFeeEnabled) {
        return 0;
      }
      
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
   function _getRewardAmount(uint256 transferAmount) view internal returns(uint256) {
      if (_zeroFeeEnabled) {
        return 0;
      }

      uint256 rewardAmount = transferAmount.mul(_rewardRate).div(100);
      return rewardAmount;
   }

   /*
    * @dev set zero fee status
    */
   function setZeroFee(bool enabled) external onlyOwner() {
      _zeroFeeEnabled = enabled;
   }


   /*
    * @dev add address to excludes 
    */
    function addToExcludes(address addr) external onlyOwner() {
        require(!_excludes[addr], "excluded address not exists");
        _excludes[addr] = true;
        _fetchNode(addr);
    }

    /*
     * @dev remove excluded address
     */
     function removeExcuded(address addr) external onlyOwner() {
        require(_excludes[addr], "excluded address not exists");
        delete _excludes[addr];
        _fetchNode(addr);
     }

   /**
    * @dev burn by send to dead address
    * return amount of token burned
    */
   function _burn(address sender, uint256 burnAmount) internal {
      if (burnAmount <= 0) {
        return;
      }

      _burnTotal = _burnTotal.add(burnAmount);
      _totalSupply = _totalSupply.sub(burnAmount);
      emit Transfer(sender, address(0x000000000000000000000000000000000000dEaD), burnAmount);
   }

   /*
    * @dev take out the total tokens burned
    */
   function totalBurn() view external returns(uint256) {
      return _burnTotal;
   }

   /*
    * @dev take out the total tokens rewards
    */
   function totalRewards() view external returns(uint256) {
      return _totalRewards;
   }

   /*
    * @dev take out the total used rewards
    */
   function totalUsedReward() view external returns(uint256) {
      return _usedRewards;
   }
   
   /** 
    * @dev check address not exists in holders list
    */
   function _holderExists(address addr) view internal returns(bool) {
       if (_holders[addr].holder == address(0)) {
           return false;
       }
       return true;
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
      _totalRewards = _totalRewards.add(amount);

      // Stop the reward distribution if the account is excluded 
      // Or the total reward remaining is less than 3000
      if ((_excludes[_nextNodeReceiveReward] && _nextNodeReceiveReward != owner()) || _totalRewards < 10**3 * 10**16) {
        return;
      }

      // reinstall the reward node if something goes wrong 
      if(!_holderExists(_nextNodeReceiveReward)) {
        _nextNodeReceiveReward = _headNode;
        return ;
      }

      // Check bonus conditions 
      // And remove from the bonus round if not meeting the requirements:
      //    balance is meet minimum requirement
      if (_balances[_nextNodeReceiveReward] < _minimumRequirementToReceiveReward) {
        _removeNode(_nextNodeReceiveReward);
        return ;
      }

      // Calculate reward for this holder
      // The reward received corresponds to the ratio of the amount held to the total supply
      // rewardsWillReceived = balance_of_hodler * (_totalRewards / totalSuppy)
      uint256 rewardsWillReceived = _balances[_nextNodeReceiveReward].mul(_totalRewards).div(_totalSupply);

      // update remaining reward
      _totalRewards = _totalRewards.sub(rewardsWillReceived);

      // give reward !
      _balances[_nextNodeReceiveReward] = _balances[_nextNodeReceiveReward].add(rewardsWillReceived);
      _holderTotalReceived[_nextNodeReceiveReward] = _holderTotalReceived[_nextNodeReceiveReward].add(rewardsWillReceived);

      // add to used rewards
      _usedRewards = _usedRewards.add(rewardsWillReceived);

      // move to next node
      if (_nextNodeReceiveReward == _tailNode) {
        _nextNodeReceiveReward = _headNode;
      }
      else {
        _nextNodeReceiveReward = _holders[_nextNodeReceiveReward].nextHolder;
      }
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
   * @dev Add new owner if the current address is not ever transaction before
   * just update recipient, because this address alway have tokens to received reward
   * update excluded value
   */
   function _addNewNode(address holderAddr) internal {
      if (_excludes[holderAddr]) {
        return;
      }

      _holders[holderAddr] = HolderNode(holderAddr, address(0), address(0));
      _holders[holderAddr].previousHoder = _tailNode;
      _holders[_tailNode].nextHolder = holderAddr;
      _tailNode = holderAddr;
      emit NewHolder(holderAddr);
   }

   /**
    * @dev get Holder Node information
    */
   function getNodeInfomation (address addr) view external onlyOwner() returns(
      address holder, 
      address previousHoder,
      address nextHolder, 
      bool isExcluded) {
      return (_holders[addr].holder, _holders[addr].previousHoder, _holders[addr].nextHolder, _excludes[addr]);
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

      if((_balances[holderAddr] < _minimumRequirementToReceiveReward) ||
        _excludes[holderAddr] && holderAddr != owner()) {
          _removeNode(holderAddr);
      }
      else if(!_holderExists(holderAddr)) {
          _addNewNode(holderAddr);
      }
    }

   /**
    * @dev remove node
    */
    function _removeNode(address loser) internal {
      if (!_holderExists(loser)) {
        return;
      }

      address pAddr = _holders[loser].previousHoder;

      bool isNextReceiveReward = false;
      if (loser == _nextNodeReceiveReward) {
        isNextReceiveReward = true;
      }
      
      // if end node is same with tail node,
      // set tail node to previous node 
      if (loser == _tailNode) {
          _holders[pAddr].nextHolder = address(0);
          _tailNode = pAddr;

          // move _nextNodeReceiveReward to head node
          if (isNextReceiveReward) {
            _nextNodeReceiveReward = _headNode;
          }
      }
      // if is middle node, then setup both previous and next node
      else {
          address nAddr = _holders[loser].nextHolder;
          _holders[pAddr].nextHolder = nAddr;
          _holders[nAddr].previousHoder = pAddr;

          // move _nextNodeReceiveReward to next node
          if (isNextReceiveReward) {
            _nextNodeReceiveReward = nAddr;
          }
      }

      // remove node
      delete _holders[loser];
      emit NewLoser(loser);
    }
}