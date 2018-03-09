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
contract WhalesburgCrowdsale is TokenERC20 {
    using SafeMath for uint;

    address multisig = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // address for ethereum 2
    address escrow = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; // address for freezing support's tokens 3
    address bounty = 0x7B97BF2df716932aaED4DfF09806D97b70C165d6; // адрес для баунти токенов 4
    address privateInvestors = 0xADc50Ae48B4D97a140eC0f037e85e7a0B13453C4; // счет для средст инветосров PreICO 5
    address developers = 0x7c64258824cf4058AACe9490823974bdEA5f366e; // 6
    address founders = 0x253579153746cD2D09C89e73810E369ac6F16115; // 7

    uint public startICO = 1520338635; // 1522458000  /03/31/2018 @ 1:00am (UTC) (GMT+1)
    // start TokenSale block
    uint public endICO = startICO + 604800;//2813100; // + 5 days
    // End TokenSale block
    uint privateSaleTokens = 46200000;
    // tokens for participants preICO
    uint foundersReserve = 10000000;
    // frozen tokens for Founders
    uint developmentReserve = 20500000;
    // frozen tokens for Founders
    uint bountyReserve = 3500000;
    // tokes for bounty program
    uint maxDayLimetSale; // от номера блокаи
    // variable for
    uint public hardCap = 1421640000000000000000;
    // 1421.64 ether
    uint256 public investors;


    bool public isFinalized = false;
    bool  distribute = false;

    uint public weisRaised;
    // collect ethereum

    mapping(address => uint) public WhiteList;
    // храним список WhiteList
    mapping (address => bool) onChain;
    address[] tokenHolders;  // tokenHolders.length
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
        // отправили средства баунти
        _transfer(this, bounty, bountyReserve*DEC);
        // отправили средства ранних инветосторов
        _transfer(this, privateInvestors, privateSaleTokens*DEC);
        // отправили средства для заморозки (developmentReserve+foundersReserve)
        _transfer(this, escrow, (developmentReserve+foundersReserve)*DEC);
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
        avaliableSupply -= 80200000*DEC;
        distribute = true;
    }
    function sell(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(DEC).div(buyPrice);
        require(amount > avaliableSupply); // проверка что запрашиваемое количество токенов меньше чем есть на балансе
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
        if (!onChain[msg.sender]) {
            tokenHolders.push(msg.sender);
            onChain[msg.sender] = true;
        }
        investors = tokenHolders.length;
    }
    function () isUnderHardCap public payable {
        //require(block > startIcoBlock && block < endIcoBlock); - неправильно
        // проверка что отправляемые средства >= 0,01 ethereum
        sell(msg.sender, msg.value);
        assert(msg.value >= 1 ether / 100);
        // добавляем получаные средства в собранное
        weisRaised = weisRaised.add(msg.value);
        // добавляем в адрес инвестора количество инвестированных эфиров
        multisig.transfer(msg.value);
    }
    /* function transferFromFrozen() public holdersSupport {
    } */
}