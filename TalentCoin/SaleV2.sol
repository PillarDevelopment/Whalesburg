pragma solidity ^0.4.21;

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
    function mintFromICO(address _to, uint256 _amount) external  returns(bool);
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

contract Sale is Ownable {

    ERC20 public token;

    using SafeMath for uint;

    address public backEndOperator = msg.sender;
    address team = 0x0cdb839B52404d49417C8Ded6c3E2157A06CdD37; // 25%
    address reserve = 0xCe66E79f59eafACaf4CaBaA317CaB4857487E3a1; // 15%

    mapping(address=>bool) public whitelist;
    mapping(address => uint256) public investedEther;

    uint256 public startSale = 1530576001; // 03 Июля 2018  UTC
    uint256 public endSale = 1538351999; // 09/30/2018 @ 11:59pm (UTC)

    uint256 public investors;
    uint256 public weisRaised;
    uint256 public dollarRaised; // количество собранных средств в долларах
    uint256 public softCap; // = 10000*1e18; // 10,000,000 USD почему то 20 вместо 10
    uint256 public hardCap; // = 75000*1e18; // 75,000,000 USD 2 личших знака
    uint256 public buyPrice; //0.01 USD
    uint256 public dollarPrice;
    uint256 public soldTokens;

    uint256 step1Sum = 3000000*1e18; // 3 млн $
    uint256 step2Sum = 5000000*1e18; // 5 млн $
    uint256 step3Sum = 10000000*1e18; // 10 млн $
    uint256 step4Sum = 20000000*1e18; // 20 млн $
    uint256 step5Sum = 30000000*1e18; // 30 млн $
    uint256 step6Sum = 45000000*1e18; // 45 млн $

    event Finalized();
    event Authorized(address wlCandidate, uint timestamp);
    event Revoked(address wlCandidate, uint timestamp);

    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }

    modifier backEnd() {
        require(msg.sender == backEndOperator || msg.sender == owner);
        _;
    }

    function Sale(uint256 _dollareth) public {
        dollarPrice = _dollareth;
        buyPrice = 1e16/dollarPrice; // 16 знаков потому что 1 цент
        softCap = 1000000000*buyPrice;
        hardCap = 7500000000*buyPrice;
    }

    function setToken (ERC20 _token) public onlyOwner {
        token = _token;
    }

    function setDollarRate(uint256 _usdether) public onlyOwner {
        dollarPrice = _usdether;
        buyPrice = 1e16/dollarPrice; // 16 знаков потому что 1 цент
        softCap = 1000000000*buyPrice;
        hardCap = 7500000000*buyPrice;
    }

    function setStartSale(uint256 newStartSale) public onlyOwner {
        startSale = newStartSale;
    }

    function setEndSale(uint256 newEndSaled) public onlyOwner {
        endSale = newEndSaled;
    }

    function setBackEndAddress(address newBackEndOperator) public onlyOwner {
        backEndOperator = newBackEndOperator;
    }

    /*******************************************************************************
     * Whitelist's section
     */
    // с сайта backEndOperator авторизует инвестора
    function authorize(address wlCandidate) public backEnd  {

        require(wlCandidate != address(0x0));
        require(!isWhitelisted(wlCandidate));
        whitelist[wlCandidate] = true;
        investors++;
        emit Authorized(wlCandidate, now);
    }
    // отмена авторизации
    function revoke(address wlCandidate) public  onlyOwner {
        whitelist[wlCandidate] = false;
        investors--;
        emit Revoked(wlCandidate, now);
    }
    // проверка
    function isWhitelisted(address wlCandidate) internal view returns(bool) {
        return whitelist[wlCandidate];
    }
    /*******************************************************************************
     * Payable's section
     */
    function isMainSale() public constant returns(bool) {
        return now >= startSale && now <= endSale;
    }

    function () public payable isUnderHardCap {
        require(isMainSale()); // проверка что идет распродажа
        require(isWhitelisted(msg.sender)); // проверка что в листе
        require(msg.value >= 10000000000000000); // проверка на минимальную сумму
        mainSale(msg.sender, msg.value);
    }

    function mainSale(address _investor, uint256 _value) internal {
        uint256 tokens = _value.mul(1e18).div(buyPrice);
        uint256 tokensSum = tokens.mul(discountSum(msg.value)).div(100);
        uint256 tokensCollect = tokens.mul(discountCollect()).div(100);
        tokens = tokens.add(tokensSum).add(tokensCollect);
        token.mintFromICO(_investor, tokens);

        uint256 tokensFounders = tokens.mul(5).div(12); //5/12
        token.mintFromICO(team, tokensFounders);

        uint256 tokensDevelopers = tokens.div(4); // 1/4
        token.mintFromICO(reserve, tokensDevelopers);

        weisRaised = weisRaised.add(msg.value);
        uint256 valueInUSD = msg.value.mul(dollarPrice);
        dollarRaised = dollarRaised.add(valueInUSD);
        investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
        soldTokens = soldTokens.add(tokens);
    }

    function discountSum(uint256 _tokens) pure private returns(uint256) {
        if(_tokens >= 10000000*1e18) { // > 100k $ = 10 000 000 TLN
            return 7;
        }
        if(_tokens >= 5000000*1e18) { // 50 - 100k $ = 5 000 000 TLN
            return 5;
        }
        if(_tokens >= 1000000*1e18) { // 10-50K $ = 1 000 000 TLN
            return 3;
        } else
            return 0;
    }

    function discountCollect() view private returns(uint256) {

        // 30% скидка, если сумма сбора не привышает 3 млн $
        if(dollarRaised <= step1Sum) {
            return 30;
        } // 25% скидка, если сумма сбора не привышает 5 млн $
        if(dollarRaised <= step2Sum) {
            return 25;
        } // 20% скидка, если сумма сбора не привышает 10 млн $
        if(dollarRaised <= step3Sum) {
            return 20;
        } // 15% скидка, если сумма сбора не привышает 20 млн $
        if(dollarRaised <= step4Sum) {
            return 15;
        } // 10% скидка, если сумма сбора не привышает 30 млн $
        if(dollarRaised <= step5Sum) {
            return 10;
        } // 5% скидка, если сумма сбора не привышает 45 млн $
        if(dollarRaised <= step6Sum) {
            return 5;
        }
        return 0;
    }

    function mintManual(address _investor, uint256 _value) public onlyOwner {
        token.mintFromICO(_investor, _value);

        uint256 tokensFounders = _value.mul(5).div(12); //5/12
        token.mintFromICO(team, tokensFounders);

        uint256 tokensDevelopers = _value.div(4); // 1/4
        token.mintFromICO(reserve, tokensDevelopers);
    }

    function refundICO() public {
        require(weisRaised < softCap && now > endSale);
        uint rate = investedEther[msg.sender];
        require(investedEther[msg.sender] >= 0);
        investedEther[msg.sender] = 0;
        msg.sender.transfer(rate);
        weisRaised = weisRaised.sub(rate);
    }

    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        require(amount != 0);
        require(_to != 0x0);
        _to.transfer(amount);
    }
}