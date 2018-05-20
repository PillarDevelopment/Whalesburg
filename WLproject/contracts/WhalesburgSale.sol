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
WeiRaised*/

pragma solidity ^0.4.21;
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

interface ERC20 {
    function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
    function transferFromICO(address _to, uint256 _value) external returns(bool);
    function burn(address _to, uint256) external returns(bool);
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
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
/*************************************************************************************************************/
contract WhalesburgCrowdsale is Ownable {
    using SafeMath for uint;

    ERC20 public token;

    address public multisig = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // address for ethereum 2
    address  escrow = 0x7eDE8260e573d3A3dDfc058f19309DF5a1f7397E; // address for freezing support's tokens 3
    address  bounty = 0x7B97BF2df716932aaED4DfF09806D97b70C165d6; // адрес для баунти токенов 4
    address  privateInvestors = 0xADc50Ae48B4D97a140eC0f037e85e7a0B13453C4; // счет для средст инветосров PreICO 5
    address  developers = 0x7c64258824cf4058AACe9490823974bdEA5f366e; // 6
    address  founders = 0x253579153746cD2D09C89e73810E369ac6F16115; // 7

    uint256 public startICO = 1521704287; // 1522458000  /03/31/2018 @ 1:00am (UTC) (GMT+1)
    // start TokenSale block
    uint256 public endICO = startICO + 604800;//2813100; // + 7 days
    // End TokenSale block
    uint256  privateSaleTokens = 46200000;
    // tokens for participants preICO
    uint256  foundersReserve = 10000000;
    // frozen tokens for Founders
    uint256  developmentReserve = 20500000;
    // frozen tokens for Founders
    uint256  bountyReserve = 3500000;
    // tokes for bounty program
    uint256 public individualRoundCap; // от номера
    // variable for
    uint256 public hardCap = 1421640000000000000000;
    // 1421.64 ether
    uint256 public investors; // количество инвесторов проекта
    uint256 public membersWhiteList;

    uint256 public buyPrice = 10000000000000000000;

    bool public isFinalized = false;
    bool  distribute = false;

    uint256 public weisRaised;
    //mapping (address => uint256) frozenBounty;
    //mapping (address => uint256) frozenDevelopers;
    //mapping (address => uint256) frozenFounders;
    mapping (address => bool) onChain; // для количества инвесторов
    //whitelist of members
    mapping (address => bool) whitelist;
    mapping (address => uint256) public moneySpent;

    address[] tokenHolders;

    /*    address[] public _whitelist = [
    0x253579153746cD2D09C89e73810E369ac6F16115, 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc,
    0x33648E28d3745218b78108016B9a138ab1e6dA2C, 0xD4B65C7759460aaDB4CE4735db8037976CB115bb,
    0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2, 0x0B529De38cF76901451E540A6fEE68Dd1bc2b4B3,
    0xB820e7Fc5Df201EDe64Af765f51fBC4BAD17eb1F, 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2,
    0xC032D3fCA001b73e8cC3be0B75772329395caA49]; // массив адресов вайтлиста
    */
    event Finalized();

    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }

    constructor() public  {
        //addWhiteList();
        //distributionTokens();
    }

    function setToken (ERC20 _token) public onlyOwner {
        token = _token;
    }
    // add address in whitelist
    function addWhiteList(address _whitelist) public onlyOwner{

        for (uint256 i=0; i<100; i++) {
            whitelist[_whitelist] = true;
            membersWhiteList++; // =_whitelist.length;
        }
    }

    function finalize() onlyOwner public {
        require(!isFinalized);
        require(now > endICO || weisRaised > hardCap);
        emit Finalized();
        isFinalized = true;
        //burn(avaliableSupply);
        //balanceOf[this] = 0;
    }

    function distributionTokens() internal {
        require(!distribute);
        token.transferFromICO(bounty, bountyReserve*1e18);
        token.transferFromICO(privateInvestors, privateSaleTokens*1e18);
        token.transferFromICO(escrow, (developmentReserve+foundersReserve)*1e18);
        //avaliableSupply -= 80200000*DEC;
        distribute = true;
    }

    function sell(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(1e18).div(buyPrice);
        //require(amount > avaliableSupply);
        //avaliableSupply -= _amount;
        token.transferFromICO(_investor, _amount);
        if (!onChain[msg.sender]) {
            tokenHolders.push(msg.sender);
            onChain[msg.sender] = true;
        }
        investors = tokenHolders.length;
    }

    function () isUnderHardCap public payable {
        if(isWhitelisted(msg.sender)) { // verifacation that the sender is a member of WL
            require(now > startICO && now < endICO); // chech ICO's date
            currentSaleLimit();
            moneySpent[msg.sender] = moneySpent[msg.sender].add(msg.value);
            require(moneySpent[msg.sender] <= individualRoundCap);
            assert(msg.value >= 1 ether / 20000);
            sell(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
            multisig.transfer(msg.value);
        } else {
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
    /*
    function tokenTransferFromHolding(address _to, uint256 sum) public  {
        require(now > endICO);
        require(msg.sender == developers || msg.sender == owner || msg.sender == founders);
        if (msg.sender == developers || msg.sender == owner) { // !!!нет параметров распределения
            frozenDevelopers[developers] = frozenDevelopers[developers].add(sum);
            require(frozenDevelopers[developers] <= developmentReserve);
            //_transfer(escrow, _to, sum*DEC);
        }
        else if (msg.sender == founders  && now > 1553990400) {
            frozenFounders[founders] = frozenFounders[founders].add(sum);
            require(frozenFounders[founders] <= foundersReserve);
            //_transfer(escrow, _to, sum*DEC);
        }
        else {
            revert();
        }
    }
    */
    // функции сеттеры на период тестирования
    function testSetStaerDate(uint256 newStart) public onlyOwner {
        startICO = newStart;
    }

    function testSetEndDate(uint256 newEnd) public onlyOwner {
        endICO = newEnd;
    }
}