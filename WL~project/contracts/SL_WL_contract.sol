pragma solidity ^0.4.18;

/*
* @author Ivan Borisov (2622610@gmail.com) (Github.com/pillardevelopment)
* @dev Source code hence -*
*/
/********************************************************************************************************************/
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

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract StandartToken is Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 18; //!!!!!!!!!!!!!

    //uint256 DEC = 10 ** uint256(decimals);
    address public owner;
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint public buyPrice = 1000000000000000000;
    bool public mintingFinished = false;
    mapping(address => uint256) balances;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }


    function StandartToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply;
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

    function burn(uint256 _value) internal onlyOwner returns (bool success) {
        totalSupply -= _value;
        avaliableSupply -= _value;
        Burn(this, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract MainSale is StandartToken{

    uint64 public startIco = 1523836800;
    uint64 public endIco = 1531699200;

    address public multisig = 0x253579153746cD2D09C89e73810E369ac6F16115;
    address public escrow = 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc;
    address founders = 0x33648E28d3745218b78108016B9a138ab1e6dA2C;
    address reserve = 0xD4B65C7759460aaDB4CE4735db8037976CB115bb;
    address bounty = 0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2;
    address wlCandidate;
    address[] public _whitelist = [
    0x253579153746cD2D09C89e73810E369ac6F16115, 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc,
    0x33648E28d3745218b78108016B9a138ab1e6dA2C, 0xD4B65C7759460aaDB4CE4735db8037976CB115bb,
    0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2, 0x0B529De38cF76901451E540A6fEE68Dd1bc2b4B3,
    0xB820e7Fc5Df201EDe64Af765f51fBC4BAD17eb1F, 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2,
    0xC032D3fCA001b73e8cC3be0B75772329395caA49]; // массив адресов вайтлиста

    mapping(address=>bool) public whitelist;

    uint constant foundersReserve = 23000000000000000000000000;
    uint constant reserveFund = 5000000000000000000000000;
    uint constant bountyReserve = 2000000000000000000000000;

    //bool distribute = false;
    uint public weisRaised;
    uint public hardCap = 50000000000000000000000; // 30,000,000 USD ~ 50,000 ether
    uint public softCap = 10000000000000000000000; // 10,000 Ether ~ 5,000,000 USD
    uint public bonusSum;
    bool public isFinalized = false;

    //event Finalized();



    function MainSale() public StandartToken(100000000000000000000000000, "Noize-MC", "MC"){
        distributionTokens();
    }

    function distributionTokens() internal {
        //require(!distribute);
        _transfer(this, bounty, bountyReserve);
        _transfer(this, founders, foundersReserve);
        _transfer(this, reserve, reserveFund);
        avaliableSupply -= 70000000000000000000000000;

        //distribute = true;
    }
    // отправка эфира с контракта



    //изменение даты начала ICO
    function setStartIco(uint64 newStartIco) public onlyOwner {
        startIco = newStartIco;
    }
    //изменение даты окончания ICO
    function setEndIco(uint64 newEndIco) public onlyOwner{
        endIco = newEndIco;
    }
    // изменение цены токена
    function setPrices(uint newPrice) public onlyOwner {
        buyPrice = newPrice;
    }
    // изменение hardCap
    function setHardCap(uint newhardCap) public onlyOwner {
        hardCap = newhardCap;
    }
    // изменение softCap
    function setSoftCap(uint newsoftCap) public onlyOwner {
        softCap = newsoftCap;
    }

    function () public payable {
        //require(now > startIco && now < endIco);
        bonusSum = msg.value;
        assert(msg.value >= 1 ether / 1000);

        discountDate(msg.sender, msg.value);
        discountSum(msg.sender, msg.value);

        //sell(msg.sender, msg.value);

        weisRaised = weisRaised.add(msg.value);

        multisig.transfer(msg.value);
    }
    function discountSum(address _investor, uint256 amount) internal {
        uint256 _amount = amount.div(buyPrice);
        // больше 640
        if (bonusSum > 640000000000000000000) { //  10%  350к ~ 200 ether
            _amount = withDiscount(_amount, 10);
            _transfer(this, _investor, _amount);
            // 150 - 350 7%, 272-640 ether
        } else if (bonusSum > 272000000000000000000 && bonusSum < 640000000000000000000) { // 100  - 200
            _amount = withDiscount(_amount, 7);
            _transfer(this, _investor, _amount);
            // 50 - 150 5%, 90-272 ether
        } else if (bonusSum > 90000000000000000000 && bonusSum < 272000000000000000000) { //50 - 100
            _amount = withDiscount(_amount, 5);
            _transfer(this, _investor, _amount);
            // 10 - 50 3%, 20 - 90 ether
        } else if (bonusSum > 20000000000000000000 && bonusSum < 90000000000000000000) { //5 - 50
            _amount = withDiscount(_amount, 3);
            _transfer(this, _investor, _amount);
        } else { // ничего =  revert
            _amount = withDiscount(_amount, 0);
            revert();
        }
        avaliableSupply -= _amount;
    }

    function discountDate(address _investor, uint256 amount) internal {
        uint256 _amount = amount.div(buyPrice);
        // address added in whileList
        if (whitelist[wlCandidate] = true && now > startIco + 1555200 ) {
            _amount = _amount.add(withDiscount(_amount, 25));
            // all proved 20%
        } else if (now > startIco && now < startIco + 1555200) { // 1-18-й день
            _amount = _amount.add(withDiscount(_amount, 20));
            // all proved 15%
        } else if (now > startIco + 1555200 && now < startIco + 3110400) { // 19-36 день
            _amount = _amount.add(withDiscount(_amount, 15));
            // all proved 10%
        } else if (now > startIco + 3110400 && now < startIco + 4665600) { // 37 - 54 день
            _amount = _amount.add(withDiscount(_amount, 10));
        } // all proved 5%
        else if (now > startIco + 4665600 && now < startIco + 6220800) { //55 - 72 день
            _amount = _amount.add(withDiscount(_amount, 5));
        } // 0
        else { // 3% 72 - 92 день - проверки на дату не будет(двойная)
            _amount = _amount.add(withDiscount(_amount, 3));
        }
        require(amount > avaliableSupply);
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {
        return ((_amount * _percent) / 100);
    }
    // завершение контракта
    function finalize() onlyOwner public {

        require(!isFinalized);

        require(now > endIco || weisRaised > hardCap);

        //Finalized();

        isFinalized = true;

        burn(avaliableSupply);

        balanceOf[this] = 0;
    }

    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        //amount = amount;
        _to.transfer(amount);
    }
}
