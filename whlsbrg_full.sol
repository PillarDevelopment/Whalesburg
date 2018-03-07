/*
(+)     нет софт капа
(+)     скидок нет

- проданные токены на пресейл

(+)     - ефир отправляется на мультисиг
(+)     - убрать оракул - сколько стоит доллар - была првязка к доллару

лучше сделать несколькими контрактами из за WhiteList

сроки - 8-9 марта - на аудит
тестирование ganashe

В контракте Crowdsale:

- function maxDayLimit (для ежедневного капа максимальной покупки) - 20 часов
- payable
- WhiteList - инвестор из данного списка участвует в ICO() - 10 часов
- проверка на наличие н=инвестора в WhiteList  в payable
(+)     - tokenTransferFromHolding - для отправки токенов со счета escrow
(+)     - сжигание нераспределеннх токенов -
(+)     - finalize - complete
- timeline по блокам
(+)     - харкап в 3800 eth complete

для web3.js
balanseOf
WeiRaised
*/
pragma solidity ^0.4.18;
/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
* @dev
/*********************************************************************************************************************
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
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
/*********************************************************************************************************************
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}
/*********************************************************************************************************************
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract TokenERC20 is Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    address public owner;
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

contract WhalesburgCrowdsale is TokenERC20 {
    using SafeMath for uint;

    address public multisig = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // address for ethereum 2
    address public escrow = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; // address for freezing support's tokens 3
    address public bounty = 0x7B97BF2df716932aaED4DfF09806D97b70C165d6; // адрес для баунти токенов 4
    address public privateInvestors = 0xADc50Ae48B4D97a140eC0f037e85e7a0B13453C4; // счет для средст инветосров PreICO 5
    address public developers = 0x7c64258824cf4058AACe9490823974bdEA5f366e; // 6
    address public founders = 0x253579153746cD2D09C89e73810E369ac6F16115; // 7
    address white_members;

    uint public startICO = 1520338635; // 1522458000  /03/31/2018 @ 1:00am (UTC) (GMT+1)
    // start TokenSale block
    uint public endICO = startICO + 604800;//2813100; // + 5 days
    // End TokenSale block
    uint public privateSaleInvestors = 46200000;  //  вымышленное количество - например 10%
    // tokens for participants preICO
    uint public foundersReserve = 10000000;
    // frozen tokens for Founders
    uint public developmentReserve = 20500000;
    // frozen tokens for Founders
    uint public bountyReserve = 3500000;
    // tokes for bounty program
    uint public individualRoundCap; // в переменной находится текузая дата для расчета доступных средств
    // variable for
    uint public hardCap = 1421640000000000000000;
    // 1421.64 ether

    bool public isFinalized = false;
    bool public distribute = false;

    uint public weisRaised;
    // collect ethereum

    mapping(address => bool) public White_List;
    // храним список WhiteList
    mapping(address => uint) public roundSaleLimit;

    event Finalized();

    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }
    modifier holdersSupport() { //чьи заморож токены остались (team, consult, reserve, bounty)
        require(msg.sender ==  developers|| msg.sender == founders || msg.sender == owner);
        _;
    }

    function WhalesburgCrowdsale() public TokenERC20(100000000, "Whalesburg Token", "WBT") {}

    function finalize() onlyOwner public {
        require(!isFinalized); // нельзя вызвать второй раз (проверка что не true)
        require(now > endICO || weisRaised > hardCap); // только тут поменять на блоки с времени
        //finalization();
        Finalized();
        isFinalized = true;
        Burn(msg.sender, avaliableSupply);
    }

    function distributionTokens() public onlyOwner {
        require(!distribute);
        // отправили средства баунти 3,5
        _transfer(this, bounty, bountyReserve*DEC);
        // отправили средства ранних инветосторов 10
        _transfer(this, privateInvestors, privateSaleInvestors*DEC);
        // отправили средства для заморозки (developmentReserve+foundersReserve)
        _transfer(this, escrow, (developmentReserve+foundersReserve)*DEC);
        avaliableSupply -= 80200000*DEC;
        distribute = true;
    }

    function maxDayLimit() internal {
        if(now > startICO && now <  startICO + 7200 ) { //первые 2 часа с начала
            individualRoundCap = 500000000000000000; //0,5 ETH
        } else if(now >= startICO + 7200 && now < startICO + 14400) { //следующие 2 часа
            individualRoundCap = 2000000000000000000; // 2 ETH
        } else if(now >= startICO + 14400 && now < startICO + 86400) { // следующие 20 часов
            individualRoundCap = 10000000000000000000; // 10 ETH
        } else if(now >= startICO + 86400 && now < endICO) { // следующие 6 дней
            individualRoundCap = 1400000000000000000000; //1400 ETH
        } else { // далее
            revert();
        }
    }

    function sell(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(DEC).div(buyPrice);
        if(White_List[white_members] == true) {
            maxDayLimit(); //
            require(_amount <= roundSaleLimit[_investor]); // проверили что кап не достигнут
            _transfer(this, _investor, _amount);
            roundSaleLimit[_investor] = roundSaleLimit[_investor].sub(_amount); // добавили купленное в mappig инвестора
            //cap = cap+_amount;
        } else {
            revert();
        }

        require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        avaliableSupply -= _amount;
        //_transfer(this, _investor, _amount);
    }

    function () isUnderHardCap public payable {
        require(now > startICO && now < endICO); //- даты ICO
        assert(msg.value >= 1 ether / 100); // проверка что средства не меньше чем 1 токен
        sell(msg.sender, msg.value);
        //beneficiary.transfer(msg.value); // средства отправляюся на адрес бенефециара
        // добавляем получаные средства в собранное
        weisRaised = weisRaised.add(msg.value);
        // добавляем в адрес инвестора количество инвестированных эфиров
        //balances[msg.sender] = balances[msg.sender].add(msg.value);
        multisig.transfer(msg.value);
    }

    function transferFromFrozen(address _investor, uint256 amount) public holdersSupport {
        require(now > endICO);
        // вывод средств на счет фаундеров
        if(msg.sender == founders && now > 1552608001) { // 03/15/2019 @ 12:00am (UTC)
            _transfer(escrow, founders, foundersReserve*DEC);
            // вывод средств на счет девелоперов
        } else if(msg.sender == developers && now > endICO) { //нет параметров проерки, пускай будет конец ICO
            _transfer(escrow, developers, developmentReserve*DEC);
            // владелец контракта распределяет средства
        } else if(msg.sender == owner) {
            _transfer(escrow, _investor, amount);
        }
    }
}