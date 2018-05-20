pragma solidity ^0.4.19;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

0xeccfa521a7f40c34d3218236feda68242c9d4ad9, 0x81cfe8efdb6c7b7218ddd5f6bda3aa4cd1554fd2, 100, 1526417758, 86400, 43200