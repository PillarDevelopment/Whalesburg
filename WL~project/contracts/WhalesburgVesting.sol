pragma solidity ^0.4.23;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract TokenVesting is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Released(uint256 amount);
    event Revoked();
    event NewGrant(address granter, address vester, address token, uint256 vestedAmount, uint64 startTime, uint64 cliffTime, uint64 endTime);

    address public beneficiary; // получатель токенов после выпуска

    uint256 public cliff1 = 7776000; // 3 mounth
    uint256 public cliff2 = 15552000; // 6 mounth
    uint256 public cliff3 = 31536000; // 12 mounth

    uint256 public start;
    uint256 public duration = 31536000; // 1 year

    uint256 constant first_volume_amount = 1000000000000000000000000; // 1,000,000 WBT
    uint256 constant second_volume_amount = 4000000000000000000000000; // 4,000,000 WBT
    uint256 constant third_volume_amount = 15500000000000000000000000; // 15,500,000 WBT

    bool public revocable = true;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

    constructor(  // 0xC032D3fCA001b73e8cC3be0B75772329395caA49, 1526461102, 600, 1200, true
        address _beneficiary,
        uint256 _start,
    //uint256 _cliff1, // 3 mounth
    //uint256 _cliff2, // 6 mouth
    //uint256 _cliff3, // 12 mounth
    //uint256 _duration,
        bool _revocable)
    public
    {
        require(_beneficiary != address(0));
        //require(_cliff1+_cliff2+_cliff3 <= duration);
        beneficiary = _beneficiary;
        revocable = _revocable;
        //duration = _duration;
        //cliff1 = start.add(_cliff1);
        //cliff2 = start.add(_cliff2);
        //cliff3 = start.add(_cliff3);
        start = _start;
    }

    /*
    function createVesting(
        //address _token,
        //address _vester,
        uint256 _vestedAmount,
        //uint64 _startTime,
        //uint64 _grantPeriod,
        uint64 _cliffPeriod)
        external
    {
        require(_token != 0);
        require(_vester != 0);
        require(_cliffPeriod <= _grantPeriod);
        require(_vestedAmount != 0);
        require(_grantPeriod==0 || _vestedAmount * _grantPeriod >= _vestedAmount); // no overflow allow here! (to make getBalanceVestingInternal safe).

        // verify that there is not already a grant between the addresses for this specific contract.
        require(grantPerTokenGranterVester[_token][msg.sender][_vester].vestedAmount==0);

        var cliffTime = _startTime.add(_cliffPeriod);
        var endTime = _startTime.add(_grantPeriod);

        grantPerTokenGranterVester[_token][msg.sender][_vester] = Grant(_vestedAmount, _startTime, cliffTime, endTime, 0);

        // update the balance
        balancePerPersonPerToken[_token][msg.sender] = balancePerPersonPerToken[_token][msg.sender].sub(_vestedAmount);

        emit NewGrant(msg.sender, _vester, _token, _vestedAmount, _startTime, cliffTime, endTime);
    }
    */





    /* @notice отправка vested tokens бенефициару*/
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);
        require(unreleased > 0);
        released[token] = released[token].add(unreleased);
        token.safeTransfer(beneficiary, unreleased);
        emit Released(unreleased);
    }

    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);
        uint256 balance = token.balanceOf(this);
        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);
        revoked[token] = true;
        token.safeTransfer(owner, refund);
        emit Revoked();
    }
    /* @dev Вычисляет сумму, которая уже vested но еще не высобожден.*/
    function releasableAmount(ERC20Basic token) public view returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }
    /* @dev Вычисляет сумму, которая уже vested.*/
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this); // общий баланс токенов на данном счете
        uint256 totalBalance = currentBalance.add(released[token]); //общий баланс +

        if (block.timestamp < cliff1) {
            return 0; // ничего если еще не прошел холд
        } else if (block.timestamp >= start.add(duration) || revoked[token]) {
            return totalBalance; //возврат всех средств если дюрация прошла
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration); // возврт пропорции = общий баланс*(now - star) / продолжительность
        }
    }
}
/*
Есть контракт TokenVesting factory. Его функционал:

На этом контракте лежит 20.5 mln WBT. Он призван по правилам, описанным в Whitepaper распределять этот пул токенов.

Этот контракт имеет 2 метода + функционал ownership:

constructor(first_volume_amount, second_volume_amount, third_volume_amount)

Параметры first_volume_amount, second… — объемы WBT которые могут быть розданы в течении 3, 6 и 12 месяцев с момента деплоя контракта соответственно. Их сумма должна быть равна 20.5 mln WBT.

build(amount, beneficiary, start, cliff, duration, revocable) onlyOwner
Данный метод вызывет new https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/TokenVesting.sol с соответствующими параметрами и пересылает туда указанное кол-во WBT.
Как связаны параметры из constructor с этим методом?
Нам нужно обеспечить гарантию того, что мы выпустим не больше токенов из Development пула, чем мы обещали в Whitepaper до полного их unlock-a. Собственно, для этого и нужны параметры в constructor. Связь идет через cliff & duration параметры: cliff должен быть не меньше времени, которое осталось до первой обещанной разблокировки. Общая сумма токенов, на контрактах соответствующих определенному периоду лока не должна превышать соответствующий лимит из конструктора.

Пример 1:
1. Создаем Factory: f = new (1mln WBT, 4mln WBT, 15.5mln WBT)
2. Делаем f.build(1mln, 0x..0, block.current, 3month, …)
Тут мы выделили весь 1 mln токенов, которые мы могли использовать через 3 месяца. Если попробовать вызвать еще раз 2 строку, то должна появлятся ошибка.

Пример 2:
1. Создаем Factory: f = new (1mln WBT, 4mln WBT, 15.5mln WBT)
2. Делаем f.build(0.5mln, 0x..0, block.current, 3month, …)
3. Делаем f.build(0.5mln, 0x..0, block.current, 3month, …)
Ошибки не должно быть.

Пример 3:
1. Создаем Factory: f = new (1mln WBT, 4mln WBT, 15.5mln WBT)
2. Делаем f.build(1mln, 0x..0, block.current, 3month, …)
3. Делаем f.build(2mln, 0x..0, block.current, 6month, …)
Ошибки не должно быть.

Пример 4:
1. Создаем Factory: f = new (1mln WBT, 4mln WBT, 15.5mln WBT)
2. Делаем f.build(1mln, 0x..0, block.current, 3month, …)
3. Делаем f.build(2mln, 0x..0, block.current, 6month, …)
4. Делаем f.build(30mln, 0x..0, block.current, 18month, …)
4 шаг вылетает с ошибкой — недостаточно средств.
*/