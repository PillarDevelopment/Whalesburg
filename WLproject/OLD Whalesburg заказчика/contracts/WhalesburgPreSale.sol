pragma solidity ^0.4.19;

import "./WhalesburgToken.sol";
import "./WhalesburgRefundVault.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";

/**
 * @title WhalesburgPreSale
 * @dev TODO
 */
contract WhalesburgPreSale is Pausable {
  using SafeMath for uint;

  string public constant name = "Whalesburg Token Pre-Sale";

  // The token being sold
  WhalesburgToken public token;

  // start and end blocks where investments are allowed (both inclusive)
  uint public startBlock;
  uint public endBlock;

  // soft and hard Caps
  uint public softCap;
  uint public hardCap;

  // refund vault used to hold funds while crowdsale is running
  WhalesburgRefundVault public vault;

  // how many token units a buyer gets per Usd Mill https://en.wikipedia.org/wiki/Mill_(currency)
  uint public WBTUSDMillsRate = 480;

  // ETH -> USD exchange rate in Mills
  uint public ETHUSDMillsRate;

  // amount of raised money in wei
  uint public weiRaised;

  // amount of tokens sold
  uint public tokensSold;

  bool public softCapReached = false;
  bool public hardCapReached = false;

  bool public isFinalized = false;

  event hardCapWasReached();

  event Finalized();

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

  function WhalesburgPreSale(
    uint _startBlock,
    uint _endBlock,
    address _token,
    uint _softCapWBT,
    uint _hardCapWBT,
    uint _baseEthUsdPrice,
    address _wallet
  ) public {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_hardCapWBT > _softCapWBT);
    require(_wallet != address(0));

    token = WhalesburgToken(_token);
    startBlock = _startBlock;
    endBlock = _endBlock;
    vault = new WhalesburgRefundVault(_wallet);
    softCap = _softCapWBT.mul(1 ether);
    hardCap = _hardCapWBT.mul(1 ether);
    ETHUSDMillsRate = _baseEthUsdPrice.mul(100);
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint weiAmount = msg.value;

    // calculate token amount to be created
    uint tokens = weiAmount.mul(ETHUSDMillsRate).div(WBTUSDMillsRate);

    uint newTokensSold = tokensSold + tokens;

    require(newTokensSold <= hardCap);

    if(!softCapReached && newTokensSold >= softCap) {
      softCapReached = true;
      vault.softCapWasReached();
    }

    if(!hardCapReached && newTokensSold == hardCap) {
      hardCapReached = true;
      hardCapWasReached();
    }

    // update state
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = newTokensSold;

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    vault.deposit.value(msg.value)(msg.sender);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = block.number >= startBlock && block.number <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && !hardCapReached;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return block.number > endBlock || hardCapReached;
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() external {
    require(isFinalized);
    require(!softCapReached);

    vault.refund(msg.sender);
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner external {
    require(!isFinalized);
    require(hasEnded());

    token.burn(token.balanceOf(this));

    if (softCapReached) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
    Finalized();

    isFinalized = true;
  }
}

pragma solidity ^0.4.18;

import "../../../math/SafeMath.sol";
import "../../../ownership/Ownable.sol";


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    /**
     * @param _wallet Vault address
     */
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    /**
     * @param investor Investor address
     */
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    /**
     * @param investor Investor address
     */
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }
}
