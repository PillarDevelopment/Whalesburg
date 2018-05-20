pragma solidity ^0.4.19;

import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Approved Burnable
 * @dev Token that can be irreversibly burned (destroyed) by BurnAgent. It's needed to take comissions for mining on Whalesburg Smart Mining Pool.
 */

contract ApprovedBurnableToken is BurnableToken, Ownable {
  address public burnAgent;

  event burnAgentChanged(address indexed previousBurnAgent, address indexed newBurnAgent);

  /**
   * @dev Throws if called by any account other than the burnAgent.
   */
  modifier onlyBurnAgent() {
    require(msg.sender == burnAgent);
    _;
  }


  /**
   * @dev Allows the current owner to change burnAgent.
   * @param newBurnAgent The address of new burnAgent.
   */
  function changeBurnAgent(address newBurnAgent) onlyOwner public {
    require(newBurnAgent != address(0));
    burnAgentChanged(burnAgent, newBurnAgent);
    burnAgent = newBurnAgent;
  }

  /**
   * @dev Burns tokens from miner's address to take comission for Whalesburg Smart Mining Pool.
   * @param _from The address of miner.
   * @param _value Amount of tokens to burn.
  */
  function burnFrom(address _from, uint _value) onlyBurnAgent public returns (bool success) {
    require(_from != address(0) && _value > 0 && balances[_from] >= _value);
    require(_value <= allowed[_from][burnAgent]);

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][burnAgent] = allowed[_from][burnAgent].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);

    return true;
  }
}
