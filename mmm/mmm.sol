pragma solidity ^0.4.19;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  
 
}


contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

 
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {
 
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

/**
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
  function Ownable() {
    owner = msg.sender;
  }
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
 
 
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
 
  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  
   function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    if(b==0) return 1;
    assert(b>=0);
    uint256 c = a ** b;
    assert(c>=a );
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
  
function compoundInterest(uint256 depo, uint256 stage2, uint256 start, uint256 current)  internal pure returns (uint256)  {
            assert(current>=start);
            assert(start>=stage2);
            uint256 ret=depo; uint g; uint d;
            stage2=stage2/1 days;
            start=start/1 days;
            current=current/1 days;
    
            uint dpercent=100;
            uint i=start;
            
            if(i-stage2>365) dpercent=200;
            if(i-stage2>730) dpercent=1000;         
            
            while(i<current)
            {

                g=i-stage2;         
                if(g>265 && g<=365) 
                {       
                    d=365-g;
                    ret=fracExp(ret, dpercent, d, 8);
                    i+=d;
                    dpercent=200;
                }
                if(g>630 && g<=730) 
                {               
                    d=730-g;                    
                    ret=fracExp(ret, dpercent, d, 8);
                    i+=d;
                    dpercent=1000;                  
                }
                else if(g>730) dpercent=1000;               
                else if(g>365) dpercent=200;
                
                if(i+100<current) ret=fracExp(ret, dpercent, 100, 8);
                else return fracExp(ret, dpercent, current-i, 8);
                i+=100;
                
            }

            return ret;
            
            
    
    
    }


function fracExp(uint256 depo, uint percent, uint period, uint p)  internal pure returns (uint256) {
  uint s = 0;
  uint N = 1;
  uint B = 1;
  

  
  for (uint i = 0; i < p; ++i){
    s += depo * N / B / (percent**i);
    N  = N * (period-i);
    B  = B * (i+1);
  }
  return s;
}

}


contract MMMTokenCoin is MintableToken {
    using SafeMath for uint256;
    using SafeMath for uint;
    
    // MMMToken
    uint256 public totalSupply;
    uint countDays;
    uint currentDate;
    mapping(address => uint) dateOfStart;    
    string public constant name = "Make Much Money";
    string public constant symbol = "MMM";
    uint32 public constant decimals = 2;
    uint globalInterestDate;

    // Crowdsale 
    uint stage2StartTime;
 
    uint period;
    uint public constant softcap=50000000;
    uint public constant rate=100000;
    uint256 public constant tokensForOwner=17000000; 
    
    uint public tokensSold;
    uint public bonusTokensLeft;
    
    mapping(address => uint256) boughtWithEther;
    mapping(address => uint256) boughtWithOther;    
    mapping(address => uint256) bountyAndRefsWithEther;  
    mapping(address => uint256) referalsWithOther;  
    
    event BonusTokensGiven(address indexed to, uint256 howMuch);
    event RefundEther(address indexed to, uint256 coins, uint256 eth);    
   event DebugLog(string what, uint256 param);
   // DEBUG
    address ad1=0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    address ad2=0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
    bool bDbgEnabled=true;
    function MMMTokenCoin() payable  {  currentDate=(now/1 days)*1 days;
        //balances[msg.sender]=500;
     

        
        tokensSold=0;
        bonusTokensLeft=10000000;
        // Crowdsale
      
        currentDate=(now/1 days)*1 days;
        stage2StartTime=now+30 days;
         globalInterestDate=stage2StartTime;
        period = 30 days;
        totalSupply=932027567000;
        balances[owner]=tokensForOwner;
       
    }
    
    function updateDate(address _owner)
    {
        if(currentDate<stage2StartTime) dateOfStart[_owner]=stage2StartTime;
        else dateOfStart[_owner]=currentDate;
    }
    
  
    
    

    function daysPassed(address _owner) public constant returns (uint256 count) 
    {
        return currentDate.sub(dateOfStart[_owner]).div(1 days);
    //    return countDays.sub(startDayOf[_owner]);
        
    }
    
    function myBalance() public constant returns (uint256 balance) 
    {
        return this.balanceOf(msg.sender);
    }
    
    
    function balanceWithInterest(address _owner)  private constant returns (uint256 ret)
    {
      //  if() return balances[_owner];
        if(currentDate<stage2StartTime || _owner==owner) return balances[_owner]; 
        return balances[_owner].compoundInterest(stage2StartTime, dateOfStart[_owner], currentDate);
    }
    
    
    
    
    
   function balanceOf(address _owner) public constant returns (uint256 balance) 
   { 
        return balanceWithInterest(_owner);
   }   
   

   
  function transfer(address _to, uint256 _value) returns (bool) {
      
  //  applyInterest(msg.sender);
    balances[msg.sender] = balanceWithInterest(msg.sender).sub(_value);
    Transfer(msg.sender, _to, _value);
    if(_to==address(this)) {
        uint256 left; left=processRefundEther(msg.sender, _value);
        balances[msg.sender]=balances[msg.sender].add(left);
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    if(msg.sender==owner || _to==owner) globalInterestDate=currentDate;
    updateDate(msg.sender);



    return true;
  }
  
  
   function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
     allowed[_from][msg.sender] = _allowance.sub(_value);
    balances[_from] = balanceWithInterest(_from).sub(_value);
     Transfer(_from, _to, _value);
       if(_to==address(this)) {
        uint256 left; left=processRefundEther(_from, _value);
        balances[_from]=balances[_from].add(left);
        
    }
    else {
        balances[_to] = balanceWithInterest(_to).add(_value);
        updateDate(_to);
    }
    if(_from==owner || _to==owner) globalInterestDate=currentDate;
    updateDate(_from);

    return true;
  }
  
   
   
   //// SALE ////
  

    
    
 
    function saleIsOn() view returns(bool b){
         return currentDate<stage2StartTime;
    }
    

    
    function newDay() public   returns (bool b)
    {
       require(now>=stage2StartTime);
       uint newDate;
      
       newDate=(now/1 days)*1 days;
       
       
       uint256 interestTokensCount=tokensSold;
       if(balances[owner]<tokensForOwner) interestTokensCount=interestTokensCount.add(tokensForOwner).sub(balances[owner]);
       
       if(interestTokensCount.compoundInterest(stage2StartTime, globalInterestDate, newDate)<=totalSupply) {
             currentDate=(now/1 days)*1 days; 
             return true;
       }
       
       return false;
       
       
        
      
    }
    
    
    function sendEtherToOwner() public onlyOwner returns(uint256 e) {
        uint256 req;
        
        require(!saleIsOn());
        require(tokensSold>=softcap);
        req=tokensSold.mul(1 ether).div(rate).div(2);
        //req=total.mul(1 ether).div(rate).div(rate2);
        DebugLog("This balance is", this.balance);
        if(req>=this.balance) return 0;
    
        uint256 amount;
        amount=this.balance.sub(req);
        owner.transfer(amount);
        return amount;
        
    }
    
    function processRefundEther(address _to, uint256 _value) private returns (uint256 left)
    {
        require(!saleIsOn());
        require(_value>0);
        uint256 Ether=0; uint256 bounty=0; uint256 agents=0; uint total=0;

        uint rate2;
        if(tokensSold<softcap) rate2=1;
        else rate2=2;
        
        if(_value>=boughtWithEther[_to]) {Ether=Ether.add(boughtWithEther[_to]); _value=_value.sub(boughtWithEther[_to]); }
        else {Ether=Ether.add(_value); _value=_value.sub(Ether);}
        boughtWithEther[_to]=boughtWithEther[_to].sub(Ether);
        
        if(rate2==2) {        
            if(_value>=bountyAndRefsWithEther[_to]) {bounty=bounty.add(bountyAndRefsWithEther[_to]); _value=_value.sub(bountyAndRefsWithEther[_to]); }
            else { bounty=bounty.add(_value); _value=_value.sub(bounty); }
            bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].sub(bounty);
        }
        total=agents.add(Ether).add(bounty);
        if(_value>total) _value=_value.sub(total);
        tokensSold=tokensSold.sub(total);
       uint256 eth=total.mul(1 ether).div(rate).div(rate2);
        if(!bDbgEnabled) _to.transfer(eth);
        globalInterestDate=currentDate;
        RefundEther(_to, total, eth);
        return _value;
    }
    
    
    function refundToOtherGet(address _to)  public onlyOwner constant returns(uint256 o)
    {
        require(!saleIsOn());
                 uint rate2; uint256 Other=0;  uint256 referals=0; uint256 total=0;
        if(tokensSold<softcap) return boughtWithOther[_to];
        else return boughtWithOther[_to].add(referalsWithOther[_to]);
    
    
        
    }
    
    function refundToOtherProcess(address _to, uint256 _value) public onlyOwner returns (uint256 o) {
         require(!saleIsOn());
                 uint rate2; uint256 Other=0;  uint256 referals=0; uint256 total=0;
        if(tokensSold<softcap) rate2=1;
        else rate2=2;
        

        
        
         if(_value>=boughtWithOther[_to]) {Other=Other.add(boughtWithOther[_to]); _value=_value.sub(boughtWithOther[_to]); }
        else {Other=Other.add(_value); _value=_value.sub(Other);}
        boughtWithOther[_to]=boughtWithOther[_to].sub(Other);
        
        if(rate2==2) {        
            if(_value>=referalsWithOther[_to]) {referals=referals.add(referalsWithOther[_to]); _value=_value.sub(referalsWithOther[_to]); }
            else { referals=referals.add(_value); _value=_value.sub(referals); }
            referalsWithOther[_to]=referalsWithOther[_to].sub(referals);
        }
        
        total=Other.add(referals);
        tokensSold=tokensSold.sub(total);
        balances[_to]=balances[_to].sub(total);
        globalInterestDate=currentDate;
        return total;
        
        
    }
    
    function createTokens(address _to, uint _amount) private   returns(uint c) {
         require( saleIsOn() );
        if(_to==address(this) || _to==address(owner)) return 0;
       
        tokensSold=tokensSold.add(_amount);
        
            
        balances[_to] = balances[_to].add(_amount);
         updateDate(_to);
        Mint(_to, _amount);
    
        
        return _amount;
    }
    
    
     function createTokensFromEther()  private  {
        
        if(msg.value<1 finney || !saleIsOn() ) {
             msg.sender.transfer(msg.value);
           return;
       }
       
         uint tokens = rate.mul(msg.value).div(1 ether);

       uint created=createTokens(msg.sender, tokens);
       boughtWithEther[msg.sender]=boughtWithEther[msg.sender].add(created);

       
       if(created<tokens) {
           uint256 s=tokens-created;
           uint256 refund=s.mul(1 ether).div(rate);
           msg.sender.transfer(refund);
       }
    }
    
    
    function createTokensFromOther(address to, uint256 howMuch, address referer) public onlyOwner   { 
         require(saleIsOn());
         uint created=createTokens(to, howMuch);
         if(referer!=0) {
             giveTokensToRefererOther(referer, created.div(10));
         }
       boughtWithOther[to]= boughtWithOther[to].add(created);
    }
    
    function giveTokensToRefererOther(address _to, uint256 _amount) public onlyOwner 
    {
        require(saleIsOn());
     
        referalsWithOther[_to]=referalsWithOther[_to].add(   createTokens(_to, _amount));
    }
    
    function giveBonusTokensEther(address _to, uint256 _amount) public onlyOwner  { 

        require(_amount<=bonusTokensLeft && _amount>0);
        createTokens(_to, _amount);
        bountyAndRefsWithEther[_to]=bountyAndRefsWithEther[_to].add(_amount);
        BonusTokensGiven(_to,_amount);
        bonusTokensLeft=bonusTokensLeft.sub(_amount);
    }
    

    
    
    function() external payable {
        createTokensFromEther();
    }
      
   
  
    
}