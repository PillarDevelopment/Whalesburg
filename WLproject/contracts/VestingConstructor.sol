pragma solidity ^0.4.23;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";

interface ERC {
    function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
    function transferFromICO(address _to, uint256 _value) external returns(bool);
    function balanceOf(address who) external returns (uint256);
}

contract VestingCreator is Ownable {

    using SafeMath for uint256;

    ERC public token;
    TokenVesting public vestingToken;

    uint256 public devPool; // 21,500,000 WBT
    bool revocable;

    event CreateVesting(address spender, uint256 tokensAmount, address contractAddress);

    constructor (ERC _token) public {
        token = _token;
    }

    function tokenBalance() public returns (uint256 balance) {
        return token.balanceOf(this);
        //return devPool;
    }

    // 0x81cfe8efdb6c7b7218ddd5f6bda3aa4cd1554fd2, 1526842519, 43200, 86400, true
    function createVesting(
        uint256 tokensForVesting,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable
    ) public onlyOwner {
        devPool = token.balanceOf(this);
        require(tokensForVesting <= devPool);
        revocable = _revocable;
        vestingToken = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable);
        token.transfer(vestingToken, tokensForVesting);
        devPool = devPool.sub(tokensForVesting);
        emit CreateVesting(_beneficiary, tokensForVesting, vestingToken);
    }
}