pragma solidity ^0.4.17;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 */
contract ERC20 {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;
    bool isICOdeployed;

    function Controlled() public { controller = msg.sender; }

    /// @notice Changes the controller of the contract just once
    /// @param _newController The new controller of the contract (e.g. ICO contract)
    function changeController(address _newController) public onlyController {
        if (!isICOdeployed) {
            isICOdeployed = true;
            controller = _newController;
        } else revert();
    }
}

contract HaCoin is ERC20, Controlled {
    using SafeMath for uint256;

    // token name
    string public name = "Hack Coin";

    // token symbol
    string public symbol = "HACK";

    // token decimals
    uint256 public decimals = 18;

    // ICO started
    uint public November08_2017 = 1510132728;
    uint public November15_2017 = 1510758900;

    uint public sold = 0;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier afterICO() {
        block.timestamp > November15_2017; _;
    }

    modifier atICOtime {
        block.timestamp > November08_2017; _;
    }

    function HaCoin() public {
        totalSupply = 6500000000000 ether;
        balances[msg.sender] = 1337 ether; // Wow, I am a fat cat!
        sold = sold.add(balances[msg.sender]);
        totalSupply = totalSupply.sub(balances[msg.sender]);
    }

    function mint(uint _value, address _to) onlyController atICOtime public {
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.sub(_value);
        sold = sold.add(balances[_to]);
        Transfer(this, _to, _value);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public afterICO returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {

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
     * @return A uint256 specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract ICO is Controlled {
    mapping (address => bool) public whitelist;

    struct Desire {
        string email;
        bool active;
    }
    mapping (address => Desire) public desires;

    HaCoin hack;
    uint RATE = 2500;

    function ICO(address hackAddress, address _robotAddress,  address[] _whitelist, address[] _desires) public {

        // initialize HaCoin
        hack = HaCoin(hackAddress);

        // Add all my friends and sponsors
        for (var i=0; i<_whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
            AddParticipant(_whitelist[i]);
        }

        // Add couple chicks
        for (var j=0; j<_desires.length; j++) {
            desires[_desires[j]].email = "*Use changeEmail func to set your email.*";
            desires[_desires[j]].active = true;
            Proposal(_desires[j], "*Use changeEmail func to set your email.*");
        }

        // initialize lottery
        lotteryBlock = block.number;
        robotAddress = _robotAddress;
        NewLotteryRound(lotteryBlock);
    }

    event Proposal(address indexed who, string email);
    event RemoveProposal(address indexed who);
    event AddParticipant(address indexed who);
    //event RemoveParticipant(address indexed who);

    function proposal(string _email) public {
        require(msg.sender.balance > 1337 ether && msg.sender != controller);
        desires[msg.sender].email = _email;
        desires[msg.sender].active = true;
        Proposal(msg.sender, _email);
    }

    function changeEmail(string _email) public {
        require(desires[msg.sender].active);
        desires[msg.sender].email = _email;
        Proposal(msg.sender, _email);
    }

    function removeProposal() public {
        delete desires[msg.sender];
        RemoveProposal(msg.sender);
    }

    function addParticipant(address who) onlyController public {
        if (isDesirous(who) && who != controller) {
            whitelist[who] = true;
            delete desires[who];
            AddParticipant(who);
            RemoveProposal(who);
        }
    }

    //    function removeParticipant(address who) onlyController public {
    //    	if (isWhitelisted(who)) {
    //    		whitelist[who] = false;
    //            RemoveParticipant(who);
    //    	}
    //    }

    function buy() public payable {
        if (isWhitelisted(msg.sender)) {
            uint hacks = RATE * msg.value;
            require(hack.balanceOf(msg.sender) + hacks <= 1000 ether);
            hack.mint(hacks, msg.sender);
        }
    }

    function isWhitelisted(address who) public view returns(bool) {
        return whitelist[who];
    }

    function isDesirous(address who) public view returns(bool) {
        return desires[who].active;
    }

    function() public payable {
        buy();
    }

    address public robotAddress;
    mapping (address => uint) private playerNumber;
    address[] public players;
    uint public lotteryBlock;
    event NewLotteryBet(address who);
    event NewLotteryRound(uint blockNumber);

    function spinLottery(uint number) public {
        if (msg.sender != robotAddress) {
            playerNumber[msg.sender] = number;
            players.push(msg.sender);
            NewLotteryBet(msg.sender);
        } else {
            require(block.number - lotteryBlock > 5);
            lotteryBlock = block.number;

            for (uint i = 0; i < players.length; i++) {
                if (playerNumber[players[i]] == number) {
                    desires[players[i]].active = true;
                    desires[players[i]].email = "*Use changeEmail func to set your email.*";
                    Proposal(players[i], desires[players[i]].email);
                }
            }
            delete players; // flushing round
            NewLotteryRound(lotteryBlock);
        }
    }
}