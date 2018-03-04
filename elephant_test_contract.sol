
/*
(+)       70% на продажу, 20% команде, 10% промоутерам. Токены команде и промоутерам холдятся до конца ICO,
нераспроданные сжигаются.

Бонусная система:
Бонусы по времени: 1 этап +20% участникам вайтлиста (только для участников вайтлиста,
предоставивших эфир-адрес),
2 этап +15% любому участнику, 3 этап +10%, 4 этап +5%, 5 этап без бонусов,

Бонусы по сумму 0 - 5к без %, 5 - 50 5%, 50 - 100 10%, 100 - 200 15%, от 200 20%.

Реферальная система: 3% пригласившему, 2% приглашенному.

*

} */
pragma solidity ^0.4.18;

/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
* @dev Source code hence -
* https://github.com/PillarDevelopment/Barbarossa-Git/blob/master/contracts/BarbarossaInvestToken.sol
*
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
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    address public owner;  //0x6a59CB8b2dfa32522902bbecf75659D54dD63F95
    uint256 public totalSupply;
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

    address public escrow = 0x0cdb839B52404d49417C8Ded6c3E2157A06CdD37;
    uint public startICO = 1520172386; //Saturday, 03-Mar-18 00:00:01 UTC
    uint public endICO = 1520294399; // Monday, 05-Mar-18 23:59:59 UTC
    // Supply for team and developers
    uint256 constant teamReserve = 20000000; //15 000 000
    // Supply for advisers, consultants and other
    uint256 constant promoReserve = 10000000; //6 000 000


    address team = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; //  !!!! TEST ADDRESS
    address promo = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; //  !!!! TEST ADDRESS//

    bool distribute = false;
    uint public weisRaised;
    bool public isFinalized = false;

    uint public tokens;
    uint public bonusQTokens;

    event Finalized();

    //mapping (address => bool) public onChain;
    //address[] public tokenHolders;  // tokenHolders.length - вернет общее количество инвесторов
    //mapping(address => uint) public balances; // храним адрес инвестора и исколь он инвестировал
    //mapping(address => uint) public tokenFrozenTeam; // храним адрес разработчиков
    //mapping(address => uint) public tokenFrozenReserve; // храним адрес резервного фонда
    //mapping(address => uint) public tokenFrozenConsult; // храним адрес Консультантов
    //mapping(address => uint) public tokenFrozenBounty; // храним адрес Баунти

    function ElephantCrowdsale() public TokenERC20(100000000, "Elephant Marketing Test Token", "EMT") {}

    function discountDate(address _investor, uint256 amount) public {
        uint256 _amount = amount.mul(DEC).div(buyPrice);
        tokens = _amount;

        // адрес из whileList
        if (now > startICO  && now < startICO + 600) {
            discountSum();
            _amount = _amount.add(withDiscount(_amount, 20));
            _amount += bonusQTokens;
            // всем 15

        } else if (now > startICO + 600 && now < startICO + 1200) { // 864000 = 10 days
            discountSum();
            _amount = _amount.add(withDiscount(_amount, 15));
            _amount += bonusQTokens;
            // всем 10
        } else if (now > startICO + 1200 && now < startICO + 1800) {
            discountSum();
            _amount = _amount.add(withDiscount(_amount, 10));
            _amount += bonusQTokens;
            // всем 5
        } else if (now > startICO + 1800 && now < startICO + 2400) {
            discountSum();
            _amount = _amount.add(withDiscount(_amount, 5));
            _amount += bonusQTokens;
        } else { // ничего
            discountSum();
            _amount = _amount.add(withDiscount(_amount, 0));
            _amount += bonusQTokens;
        }
        require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
        bonusQTokens =0;
    }
    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {
        return ((_amount * _percent) / 100);
    }
    //
    function discountSum() public {
        //uint256 _amount = amount.mul(DEC).div(buyPrice);
        //require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        // от 200 000 - 20%
        if (tokens > 200000) {
            bonusQTokens = withDiscount(tokens, 20);

            // 100 - 200 15%,
        } else if (tokens > 100000 && tokens < 200000) {
            bonusQTokens = withDiscount(tokens, 15);

            // 50 - 100 10%,
        } else if (tokens > 50000 && tokens < 100000) {
            bonusQTokens = withDiscount(tokens, 10);

            // 5 - 50 5%,
        } else if (tokens > 5000 && tokens < 50000) {
            bonusQTokens = withDiscount(tokens, 5);
        } else { // ничего
            bonusQTokens = withDiscount(tokens, 0);
        }
        //require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        // _amount = _amount+bonusQTokens+bonusTimeTokens;
        //avaliableSupply -= _amount;
        //_transfer(this, _investor, _amount);
        //bonusQTokens = 0;
        //bonusTimeTokens = 0;
    }



    // функция для отправки эфира с контракта
    function withdrawEthFromContract(address _to) public onlyOwner
    {
        //require(now > endICO); // проверка когда можно вывести эфир
        _to.transfer(weisRaised);
    }
    // функция payable для отправки эфира на адрес
    function ()  public payable {
        require(now > startICO && now < endICO);
        discountDate(msg.sender, msg.value);
        // проверка что отправляемые средства >= 0,001 ethereum
        assert(msg.value >= 1 ether / 1000);
        //beneficiary.transfer(msg.value); // средства отправляюся на адрес бенефециара
        // добавляем получаные средства в собранное
        weisRaised = weisRaised.add(msg.value);
        // добавляем в адрес инвестора количество инвестированных эфиров
        //balances[msg.sender] = balances[msg.sender].add(msg.value);
    }

    // функция возврата средств инвесторам при недостижении SoftCapPreICO

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
}