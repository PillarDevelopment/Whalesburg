/*
(+)       70% на продажу, 20% команде, 10% промоутерам. Токены команде и промоутерам холдятся до конца ICO,
нераспроданные сжигаются.

Бонусная система:
Бонусы по времени: 1 этап +20% участникам вайтлиста (только для участников вайтлиста,
предоставивших эфир-адрес),
2 этап +15% любому участнику, 3 этап +10%, 4 этап +5%, 5 этап без бонусов,

Бонусы по сумму 0 - 5к без %, 5 - 50 5%, 50 - 100 10%, 100 - 200 15%, от 200 20%.

Реферальная система: 3% пригласившему, 2% приглашенному.

*/
pragma solidity ^0.4.19;

/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
* @dev Source code hence -
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

contract Ownable {
    address public owner;
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TokenERC20 is Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    address public owner;  //0x6a59CB8b2dfa32522902bbecf75659D54dD63F95
    // all tokens
    uint256 public totalSupply;
    // tokens for sale
    uint256 public avaliableSupply;  // totalSupply - all reserve
    uint256 public constant buyPrice = 1000 szabo; //0,001 ether

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply * DEC;  // Update total supply with the decimal amount
        balanceOf[this] = totalSupply;                // Give the creator all initial tokens
        avaliableSupply = balanceOf[this];            // Show how much tokens on contract
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        avaliableSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
}

contract ElephantCrowdsale is TokenERC20 {
    using SafeMath for uint;

    function ElephantCrowdsale() public TokenERC20(100000000, "Elephant Marketing Test Token", "EMT") {}

    //uint public teamToken = 20000000;
    //uint public promoToken = 10000000;
    uint public weisRaised;

    uint public startICO = 1520035201; //Saturday, 03-Mar-18 00:00:01 UTC
    uint public endICO = 1520294399; // Monday, 05-Mar-18 23:59:59 UTC

    address team = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // account 4
    address promotion = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; // account 3
    address escrow = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // account 2

    bool distribute = false;

    function distributionTokens() public onlyOwner {
        require(!distribute);

        // отправили средства команде
        _transfer(this, escrow, 30000000*DEC);

        // записать маппинги

        // founders(10 000 000) + bounthy(3 500 000) + developers(20 500 000) + InvestorsPreISO(10 000 000)
        //_transfer(this, beneficiary, (foundersReserve+developmentReserve+bounty+preICOTokens)*DEC); // frozen all
        //_transfer(this, team, 7500000*DEC); // immediately Team 1/2
        //tokenFrozenTeam[team] = tokenFrozenTeam[team].add(7500000*DEC);
        //tokenFrozenTeam[team] += 7500000*DEC; // кладем в меппинг первые токены
        //_transfer(this, consult, 2000000*DEC); // immediately advisers 1/3
        //tokenFrozenConsult[consult] = tokenFrozenConsult[consult].add(4000000*DEC); // в меппинг кладем 6 000 000 - 4 000 000
        //_transfer(this, test, 100000*DEC); // immediately testers all
        //_transfer(this, marketing, 5900000*DEC); // immediately marketing all
        //tokenFrozenReserve[reserve] = tokenFrozenReserve[reserve].add(10000000*DEC);  // immediately reserve all
        //tokenFrozenBounty[bounty] = tokenFrozenBounty[bounty].add(3000000*DEC); // immediately bounty all frozen

        avaliableSupply -= 30000000*DEC;
        distribute = true;
    }

    function sell(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(DEC).div(buyPrice);
        require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        // бонусная система
        // Бонусная система:
        // Бонусы по времени: 1 этап +20% участникам вайтлиста (только для участников вайтлиста,
        // предоставивших эфир-адрес),
        // 2 этап +15% любому участнику, 3 этап +10%, 4 этап +5%, 5 этап без бонусов,

        //  //  от 200к 20%.
        if (amount > 200000*DEC) {
            _amount = _amount.add(withDiscount(_amount, 20));
        }
        /*          // 100 - 200 15%,
                 else if (now > startIcoDate + 1728000 && now < startIcoDate + 2592000) {
                    _amount = _amount.add(withDiscount(_amount, 10));
                    // 50 - 100 10%,
                } else if (now > startIcoDate + 2592000 && now < startIcoDate + 3456000) {
                    _amount = _amount.add(withDiscount(_amount, 5));
                    // token discount 5 - 50 5%
                } else if (now > startIcoDate + 3456001 && now < endIcoDate) {
                    _amount = _amount.add(withDiscount(_amount, 5));
                    // 0 - 5к без %
                } else {
                    _amount = _amount.add(withDiscount(_amount, 0));
                }
                */
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    function ()  public payable {
        sell(msg.sender, msg.value);
        weisRaised = weisRaised.add(msg.value);
        //balances[msg.sender] = balances[msg.sender].add(msg.value);
        // средства на контракте до окончания ICO
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {
        return ((_amount * _percent) / 100);
    }

    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        // проверка что ICO закончено
        amount = amount * DEC;
        _to.transfer(amount);
    }
}