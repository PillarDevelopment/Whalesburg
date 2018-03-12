/*
totalSupply - показывает не правильно

- сделать паблик меппинг чтобы каждый по своему адресу увидел свой лимит - или доступный лимит

(+)     нет софт капа
(+)     скидок нет

(+)     проданные токены на пресейл

(+)     - ефир отправляется на мультисиг
(+)     - убрать оракул - сколько стоит доллар - была првязка к доллару

лучше сделать несколькими контрактами из за WhiteList

сроки - 8-9 марта - на аудит
тестирование ganashe

В контракте Crowdsale:

(+)     function maxDayLimit (для ежедневного капа максимальной покупки) - 20 часов
(+)      payable
(+)     WhiteList - инвестор из данного списка участвует в ICO() - 10 часов
(+)      проверка на наличие н=инвестора в WhiteList  в payable
(+)     - tokenTransferFromHolding - для отправки токенов со счета escrow
(+)     - сжигание нераспределеннх токенов -
(+)     - finalize - complete
(+)     - харкап в 3800 eth complete

для web3.js
balanseOf
WeiRaised
*/
pragma solidity ^0.4.18;

/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
* @dev Source code hence -
* https://github.com/PillarDevelopment/Barbarossa-Git/blob/master/contracts/BarbarossaInvestToken.sol
*
*/
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
    //!!!!!!!!!! не меняй его !!!!!!!!!!!!!!!!!!!
    uint256 public decimals = 8; //!!!!!!!!!!!!!
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    uint256 DEC = 10 ** uint256(decimals);
    address public owner;
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint256 public constant buyPrice = 71800000000000;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply * DEC;
        balanceOf[this] = totalSupply;
        avaliableSupply = balanceOf[this];
        name = tokenName;
        symbol = tokenSymbol;
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
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        avaliableSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
}
contract WhalesburgCrowdsale is TokenERC20 {
    using SafeMath for uint;

    address public multisig = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // address for ethereum 2
    address  escrow = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; // address for freezing support's tokens 3
    address  bounty = 0x7B97BF2df716932aaED4DfF09806D97b70C165d6; // адрес для баунти токенов 4
    address  privateInvestors = 0xADc50Ae48B4D97a140eC0f037e85e7a0B13453C4; // счет для средст инветосров PreICO 5
    address  developers = 0x7c64258824cf4058AACe9490823974bdEA5f366e; // 6
    address  founders = 0x253579153746cD2D09C89e73810E369ac6F16115; // 7

    uint public startICO = 1520840244; // 1522458000  /03/31/2018 @ 1:00am (UTC) (GMT+1)
    // start TokenSale block
    uint public endICO = startICO + 604800;//2813100; // + 5 days
    // End TokenSale block
    uint  privateSaleTokens = 46200000;
    // tokens for participants preICO
    uint  foundersReserve = 10000000;
    // frozen tokens for Founders
    uint  developmentReserve = 20500000;
    // frozen tokens for Founders
    uint  bountyReserve = 3500000;
    // tokes for bounty program
    uint public individualRoundCap; // от номера
    // variable for
    uint public hardCap = 1421640000000000000000;
    // 1421.64 ether
    uint256 public investors; // количество инвесторов проекта
    uint256 public membersWhiteList;

    bool public isFinalized = false;
    bool  distribute = false;

    uint public weisRaised;
    //

    mapping (address => uint256) frozenBounty;
    mapping (address => uint256) frozenDevelopers;
    mapping (address => uint256) frozenFounders;

    mapping (address => bool) onChain; // для количества инвесторов
    address[] tokenHolders;

    //белый лист участников
    mapping (address => bool) whitelist;
    // индексное соответствие
    mapping (address => uint256) public moneySpent;
    //

    address[] public _whitelist = [
    0x253579153746cD2D09C89e73810E369ac6F16115, 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc,
    0x33648E28d3745218b78108016B9a138ab1e6dA2C, 0xD4B65C7759460aaDB4CE4735db8037976CB115bb,
    0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2, 0x0B529De38cF76901451E540A6fEE68Dd1bc2b4B3,
    0xB820e7Fc5Df201EDe64Af765f51fBC4BAD17eb1F, 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2,
    0xC032D3fCA001b73e8cC3be0B75772329395caA49]; // массив адресов вайтлиста

    event Finalized();

    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }

    modifier holdersSupport() { //чьи заморож токены остались (team, consult, reserve, bounty)
        require(msg.sender ==  developers|| msg.sender == founders || msg.sender == owner);
        _;
    }

    function WhalesburgCrowdsale() public TokenERC20(100000000, "Whalesburg Token", "WBT") {

        addWhiteList();

        distributionTokens();
    }

    // функция добавляет адреса в вайт лист
    function addWhiteList() internal{

        for (uint i=0; i<_whitelist.length; i++) {

            whitelist[_whitelist[i]] = true;

            membersWhiteList =_whitelist.length;
        }
    }


    function finalize() onlyOwner public {

        require(!isFinalized); // нельзя вызвать второй раз (проверка что не true)

        require(now > endICO || weisRaised > hardCap); // только тут поменять на блоки с времени

        Finalized();

        isFinalized = true;

        Burn(msg.sender, avaliableSupply);
    }


    function distributionTokens() internal {

        require(!distribute);
        // отправили средства баунти
        _transfer(this, bounty, bountyReserve*DEC);
        // отправили средства ранних инветосторов
        _transfer(this, privateInvestors, privateSaleTokens*DEC);
        // отправили средства для заморозки (developmentReserve+foundersReserve)
        _transfer(this, escrow, (developmentReserve+foundersReserve)*DEC);
        // записать маппинги
        avaliableSupply -= 80200000*DEC;

        distribute = true;
    }


    function sell(address _investor, uint256 amount) internal {

        uint256 _amount = amount.mul(DEC).div(buyPrice);

        require(amount > avaliableSupply);

        avaliableSupply -= _amount;

        _transfer(this, _investor, _amount);

        if (!onChain[msg.sender]) {

            tokenHolders.push(msg.sender);

            onChain[msg.sender] = true;
        }

        investors = tokenHolders.length; // количество инвесторов всего
    }


    function () isUnderHardCap public payable {

        if(isWhitelisted(msg.sender)) { // verifacation that the sender is a member of WL

            require(now > startICO && now < endICO); // chech ICO's date

            currentSaleLimit(); // initialize current individualRoundCap
            //require(msg.value <= moneySpent[msg.sender]); // это сработает, но что если в процессе отправки он превысит лимит
            moneySpent[msg.sender] = moneySpent[msg.sender].add(msg.value);

            require(moneySpent[msg.sender] <= individualRoundCap);

            assert(msg.value >= 1 ether / 20000);

            sell(msg.sender, msg.value);

            weisRaised = weisRaised.add(msg.value);

            multisig.transfer(msg.value);

        }
        else {

            revert();
        }
    }

    function isWhitelisted(address who) public view returns(bool) {

        return whitelist[who];
    }


    function currentSaleLimit() internal {

        if(now > startICO && now <  startICO + 7200 ) { //первые 2 часа с начала

            individualRoundCap = 500000000000000000; //0,5 ETH
        }
        else if(now >= startICO + 7200 && now < startICO + 14400) { //следующие 2 часа

            individualRoundCap = 2000000000000000000; // 2 ETH
        }
        else if(now >= startICO + 14400 && now < startICO + 86400) { // следующие 20 часов

            individualRoundCap = 10000000000000000000; // 10 ETH
        }
        else if(now >= startICO + 86400 && now < endICO) { // следующие 6 дней

            individualRoundCap = hardCap; //1400 ETH
        }
        else {

            revert();
        }
    }


    function tokenTransferFromHolding(address _to, uint sum) public  holdersSupport onlyOwner {

        require(now > endICO);

        if ((msg.sender == developers && now > endICO) || msg.sender == owner) {

            frozenDevelopers[developers] = frozenDevelopers[developers].add(sum);

            require(frozenDevelopers[developers] >= developmentReserve);

            _transfer(escrow, _to, sum);
        }
        else if ((msg.sender == founders  && now > endICO) || msg.sender == owner) {

            frozenFounders[founders] = frozenFounders[founders].add(sum);

            require(frozenFounders[founders] >= foundersReserve);

            _transfer(escrow, _to, sum);
        }
        else {

            revert();
        }
    }
}