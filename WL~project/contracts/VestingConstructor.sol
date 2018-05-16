pragma solidity ^0.4.23;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract DevPoolVesting {
    // 0x81cfe8efdb6c7b7218ddd5f6bda3aa4cd1554fd2, 1526411191, 43200, 86400, true
    TokenVesting public token;

    uint256 public first_volume_amount;
    uint256 public second_volume_amount;
    uint256 public third_volume_amount;
    uint256 unixDay = 86400;
    uint256 constant devPoolTokens = 21500000000000000000000000; // 21,500,000 WBT

    event CreateVesting(address spender, uint256 tokensAmount, address contractAddress);

    constructor(
        uint256 _first_volume_amount,
        uint256 _second_volume_amount,
        uint256 _third_volume_amount
    ) public {
        first_volume_amount = _first_volume_amount*unixDay;
        second_volume_amount = _second_volume_amount*unixDay;
        third_volume_amount = _third_volume_amount*unixDay;
    }

    function createVesting(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _tokensAmount,
        bool _revocable
    ) public  {
        require(_tokensAmount >= devPoolTokens); // проверка что не превысили размер пула
        _duration = first_volume_amount*second_volume_amount*third_volume_amount;
        _revocable = false;
        token = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable);
        emit CreateVesting(_beneficiary, _tokensAmount, token);
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