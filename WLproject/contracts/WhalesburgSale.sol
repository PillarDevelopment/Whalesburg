pragma solidity 0.4.24;

/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
*/
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ERC20 {
    function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
    function transferFromICO(address _to, uint256 _value) external returns(bool);
    function balanceOf(address who) external view returns (uint256);
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/*********************************************************************************************************************
* @dev see https://github.com/ethereum/EIPs/issues/20 */
/*************************************************************************************************************/
contract WhalesburgCrowdsale is Ownable {
    using SafeMath for uint256;

    ERC20 public token;

    address public constant multisig = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // for test Only
    address constant bounty = 0x7B97BF2df716932aaED4DfF09806D97b70C165d6; //
    address constant privateInvestors = 0xADc50Ae48B4D97a140eC0f037e85e7a0B13453C4; // for test Only
    address developers = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // for test Only
    address constant founders = 0x253579153746cD2D09C89e73810E369ac6F16115; // for test Only

    uint256 public startICO = 1528041600; // Sunday, 03-Jun-18 16:00:00 UTC
    uint256 public endICO = 1530633600;  // Tuesday, 03-Jul-18 16:00:00 UTC

    uint256 constant privateSaleTokens = 46200000; // ждет уточнения
    uint256 constant foundersReserve = 10000000;
    uint256 constant developmentReserve = 20500000;
    uint256 constant bountyReserve = 3500000;

    uint256 public individualRoundCap;

    uint256 public constant hardCap = 1421640000000000000000; // 1421.64 ether

    uint256 public investors;

    uint256 public membersWhiteList;

    uint256 public constant buyPrice = 71800000000000; // 0.0000718 Ether

    bool public isFinalized = false;
    bool public distribute = false;

    uint256 public weisRaised;

    mapping (address => bool) public onChain;
    mapping (address => bool) whitelist;
    mapping (address => uint256) public moneySpent;

    address[] tokenHolders;

    event Finalized();
    event Authorized(address wlCandidate, uint256 timestamp);
    event Revoked(address wlCandidate, uint256 timestamp);

    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }

    constructor(ERC20 _token) public {
        require(_token != address(0));
        token = _token;
    }

    function setVestingAddress(address _newDevPool) public onlyOwner {
        developers = _newDevPool;
    }

    function distributionTokens() public onlyOwner {
        require(!distribute);
        token.transferFromICO(bounty, bountyReserve*1e18);
        token.transferFromICO(privateInvestors, privateSaleTokens*1e18);
        token.transferFromICO(developers, developmentReserve*1e18);
        token.transferFromICO(founders, foundersReserve*1e18);
        distribute = true;
    }

    /******************-- WhiteList --***************************/
    function authorize(address _beneficiary) public onlyOwner  {
        require(_beneficiary != address(0x0));
        require(!isWhitelisted(_beneficiary));
        whitelist[_beneficiary] = true;
        membersWhiteList++;
        emit Authorized(_beneficiary, now);
    }

    function addManyAuthorizeToWhitelist(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            authorize(_beneficiaries[i]);
        }
    }

    function revoke(address _beneficiary) public  onlyOwner {
        whitelist[_beneficiary] = false;
        emit Revoked(_beneficiary, now);
    }

    function isWhitelisted(address who) public view returns(bool) {
        return whitelist[who];
    }

    function finalize() onlyOwner public {
        require(!isFinalized);
        require(now >= endICO || weisRaised > hardCap);
        emit Finalized();
        isFinalized = true;
        token.transferFromICO(owner, token.balanceOf(this));
    }

    /***************************--Payable --*********************************************/

    function () isUnderHardCap public payable {
        if(isWhitelisted(msg.sender)) {
            require(now >= startICO && now < endICO);
            currentSaleLimit();
            moneySpent[msg.sender] = moneySpent[msg.sender].add(msg.value);
            require(moneySpent[msg.sender] <= individualRoundCap);
            sell(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
            multisig.transfer(msg.value);
        } else {
            revert();
        }
    }

    function currentSaleLimit() private {
        if(now >= startICO && now < startICO+7200) {

            individualRoundCap = 500000000000000000; //0,5 ETH
        }
        else if(now >= startICO+7200 && now < startICO+14400) {

            individualRoundCap = 2000000000000000000; // 2 ETH
        }
        else if(now >= startICO+14400 && now < startICO+86400) {

            individualRoundCap = 10000000000000000000; // 10 ETH
        }
        else if(now >= startICO+86400 && now < endICO) {

            individualRoundCap = hardCap; //1421.64 ETH
        }
        else {
            revert();
        }
    }

    function sell(address _investor, uint256 amount) private {
        uint256 _amount = amount.mul(1e18).div(buyPrice);
        token.transferFromICO(_investor, _amount);
        if (!onChain[msg.sender]) {
            tokenHolders.push(msg.sender);
            onChain[msg.sender] = true;
        }
        investors = tokenHolders.length;
    }
}