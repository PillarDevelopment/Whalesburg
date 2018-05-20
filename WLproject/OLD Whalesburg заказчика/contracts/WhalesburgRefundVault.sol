pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundVault.sol";

contract WhalesburgRefundVault is RefundVault {
  using SafeMath for uint256;

  bool public softCapReached = false;

  event SoftCapReached();

  modifier onlyWallet() {
    require(msg.sender == wallet);
    _;
  }

  modifier canWithdraw() {
    require(softCapReached);
    _;
  }

  function WhalesburgRefundVault( address _wallet) RefundVault(_wallet) public {}

  function softCapWasReached() external onlyOwner {
    softCapReached = true;
    SoftCapReached();
  }

  function withdraw(uint amount) external onlyWallet canWithdraw {
    require(amount <= this.balance);
    wallet.transfer(amount);
  }

  function depositOf(address _owner) public view returns (uint256 balance) {
    return deposited[_owner];
  }
}
