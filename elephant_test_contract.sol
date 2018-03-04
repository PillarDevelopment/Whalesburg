
/*
(+)       70% на продажу, 20% команде, 10% промоутерам.
Токены команде и промоутерам холдятся до конца ICO,
(+)       нераспроданные сжигаются.

Бонусная система:
Бонусы по времени:
1 этап +20% участникам вайтлиста (только для участников вайтлиста,
предоставивших эфир-адрес),
(+)       2 этап +15% любому участнику,
(+)       3 этап +10%,
(+)       4 этап +5%,
(+)       5 этап без бонусов,

Бонусы по сумму 0 - 5к без %,
5 - 50 5%,
50 - 100 10%,
100 - 200 15%,
от 200 20%.

Реферальная система: 3% пригласившему, 2% приглашенному.
} */
pragma solidity ^0.4.18;
/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
*/
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

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
    uint256 public decimals = 8;
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
/*********************************************************************************************************************
----------------------------------------------------------------------------------------------------------------------
* @dev YodseCrowdsale contract
*/
contract ElephantCrowdsale is TokenERC20 {
    using SafeMath for uint;

    address public multisig = 0xC032D3fCA001b73e8cC3be0B75772329395caA49;
    // address beneficiary 0x6a59CB8b2dfa32522902bbecf75659D54dD63F95
    address public escrow = 0x0cdb839B52404d49417C8Ded6c3E2157A06CdD37;
    uint public startICO = 1520035201; //Saturday, 03-Mar-18 00:00:01 UTC
    uint public endICO = 1520294399; // Monday, 05-Mar-18 23:59:59 UTC
    // Supply for team and developers
    uint256 constant teamReserve = 20000000; //15 000 000
    // Supply for advisers, consultants and other
    uint256 constant promoReserve = 10000000; //6 000 000

    mapping(address => uint) public whiteList; // храним адрес резервного фонда

    address team = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; //  !!!! TEST ADDRESS
    address promo = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; //  !!!! TEST ADDRESS//

    bool distribute = false;
    uint public weisRaised;
    bool public isFinalized = false;

    event Finalized();

    modifier holdersSupport() {
        require(msg.sender == team || msg.sender == promo );
        _;
    }

    function ElephantCrowdsale() public TokenERC20(100000000, "Elephant Marketing Test Token", "EMT") {}

    function discountDate(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(DEC).div(buyPrice);

        // адрес из whileList
        if (now > startICO  && now < startICO + 600) {
            _amount = _amount.add(withDiscount(_amount, 20));

            // всем 15
        } else if (now > startICO + 600 && now < startICO + 1200) { // 864000 = 10 days
            _amount = _amount.add(withDiscount(_amount, 15));

            // всем 10
        } else if (now > startICO + 1200 && now < startICO + 1800) {
            _amount = _amount.add(withDiscount(_amount, 10));

            // всем 5
        } else if (now > startICO + 1800 && now < startICO + 2400) {
            _amount = _amount.add(withDiscount(_amount, 5));
        } else { // ничего
            _amount = _amount.add(withDiscount(_amount, 0));
        }
        require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {
        return ((_amount * _percent) / 100);
    }

    // функция для отправки эфира с контракта
    function withdrawEthFromContract(address _to) public onlyOwner
    {
        require(now > endICO); // проверка когда можно вывести эфир
        _to.transfer(weisRaised);
    }
    // функция payable для отправки эфира на адрес
    function ()  public payable {
        require(now > startICO && now < endICO);
        discountDate(msg.sender, msg.value);
        assert(msg.value >= 1 ether / 1000);
        weisRaised = weisRaised.add(msg.value);
        multisig.transfer(msg.value);
    }

    function finalize() onlyOwner public {
        require(!isFinalized); // нельзя вызвать второй раз (проверка что не true)
        require(now > endICO);

        finalization();
        Finalized();

        isFinalized = true;
        Burn(msg.sender, avaliableSupply);
    }

    function finalization() internal pure {
    }

    function distributionTokens() public onlyOwner {
        require(!distribute);
        _transfer(this, escrow, 30000000*DEC); // frozen all
        avaliableSupply -= 30000000*DEC;
        distribute = true;
    }

    function tokenTransferFromHolding() public  holdersSupport {
        //require(!transferFrozen);
        //require(now > endICO);

        if (msg.sender == team) {
            //require(tokenFrozenTeam[team] == 20000000*DEC);  // не может быть меньше так как даже если они выведут токены - на меппинг это не отразится
            //require(tokenFrozenReserve[reserve] == 7500000*DEC;);
            _transfer(escrow, team, 20000000*DEC);
            balanceOf[escrow] = balanceOf[escrow].sub(20000000*DEC); // списали с бенефициара
            //tokenFrozenTeam[team] = 0; // списали с мепинга и сделали его == 0 чтобы второй раз не вывели
        }

        // !!! team - 7 500 000 после 1.1.2020
        else if (msg.sender == promo) { // 1577836801 - 01/01/2020 @ 12:00am (UTC)
            //require(tokenFrozenPromo[promo] == 10000000*DEC);  // не может быть меньше так как даже если они выведут токены - на меппинг это не отразится
            //tokenFrozenTeam[team] == 0;
            _transfer(escrow, promo, 10000000*DEC); // перевели еще токены
            balanceOf[escrow] = balanceOf[escrow].sub(10000000*DEC); // списали с бенефициара
            //tokenFrozenPromo[promo] = 0; // списали с мепинга и сделали его == 0 чтобы второй раз не вывели
        }
    }
}
/*
function discountSum(address _investor, uint256 amount) public {
        uint256 _amount = amount.mul(DEC).div(buyPrice);
        if (msg.value > 200000000000000000000) { // 200 ether
        _amount = _amount.add(withDiscount(_amount, 20));
        _transfer(this, _investor, _amount);
        //bonusQTokens = withDiscount(tokens, 20);
        // 100 - 200 15%,
    } else if (tokens > 100000000000000000000 && tokens < 200000000000000000000) { // 100 000 - 200 000
        _amount = _amount.add(withDiscount(_amount, 15));
        _transfer(this, _investor, _amount);
        // 50 - 100 10%,
    } else if (tokens > 50000000000000000000 && tokens < 100000000000000000000) {
        _amount = _amount.add(withDiscount(_amount, 10));
        _transfer(this, _investor, _amount);
        // 5 - 50 5%,
    } else if (tokens > 5000 && tokens < 50000000000000000000) {
        _amount = _amount.add(withDiscount(_amount, 5));
        _transfer(this, _investor, _amount);
    } else { // ничего
        _amount = _amount.add(withDiscount(_amount, 0));
        _transfer(this, _investor, _amount);
        }
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }
*/