var Token = artifacts.require("./WhalesBurgToken.sol");

contract('Token.Token', function(accounts) {
	it('Треть токенов должна уходить на счет владельца', () => {
		var token,
			totalSupply,
			senderBalance,
			tokenBalance

		return Token.deployed().then(instance => {
			token = instance;
			return token.totalSupply().then(result => {
				totalSupply = result.toNumber();
				return token.balanceOf(accounts[0]).then(result => {
					senderBalance = result.toNumber();
					return token.balanceOf(token.address)
				}).then(result => {
					tokenBalance = result.toNumber();
					assert.equal(senderBalance + tokenBalance, totalSupply, 'Неверно распределились токены')
				})
			})
		})
	})
})

contract('Token.transfer', function(accounts) {
	it('Должен отрабатывать, если unpause', async () => {
		var amount = 10;
		var first = accounts[0];
		var second = accounts[1];

		var token = await Token.deployed()
		var firstBalanceStart = await token.balanceOf(first)
		firstBalanceStart = firstBalanceStart.toNumber()

		var secondBalanceStart = await token.balanceOf(second)
		secondBalanceStart = secondBalanceStart.toNumber()

		await token.unpause()
		await token.transfer(second, amount, {from: first})

		var firstBalanceEnd = await token.balanceOf(first)
		firstBalanceEnd = firstBalanceEnd.toNumber()

		var secondBalanceEnd = await token.balanceOf(second)
		secondBalanceEnd = secondBalanceEnd.toNumber()

		assert.equal(firstBalanceEnd, firstBalanceStart - amount)
		assert.equal(secondBalanceEnd, secondBalanceStart + amount)

	})

	it('Не должен отрабатывать, если pause', () => {
		var token
		var amount = 10;
		var first = accounts[0];
		var second = accounts[1];

		return Token.deployed().then(instance => {
			token = instance;
			return token.pause().then(result => {
				return token.transfer(second, amount, {from: first}).then(()=>
					assert.throw('Не должен давать перевести токены'),
					e => assert.isAtLeast(e.message.indexOf('revert'), 0)
				)
			})
		})
	})

	it('Должен отрабатывать, если вызывает crowdsale', () => {
		var token,
			firstBalanceStart,
			firstBalanceEnd,
			secondBalanceStart,
			secondBalanceEnd,
			crowdsaleBalanceStart,
			crowdsaleBalanceEnd

		var amount = 10
		var first = accounts[0]
		var second = accounts[1]
		var crowdsale = accounts[2]

		return Token.deployed().then(instance => {
			token = instance
			return token.balanceOf(first).then(result => {
				firstBalanceStart = result.toNumber()
				return token.balanceOf(second).then(result => {
					secondBalanceStart = result.toNumber()
					return token.balanceOf(crowdsale).then(result => {
						crowdsaleBalanceStart = result.toNumber()
						return token.setSaleAddress(crowdsale).then(()=> {
							return token.unpause().then(()=> {
								return token.transfer(crowdsale, amount, {from: first}).then(()=> {
									return token.balanceOf(first).then(result => {
										firstBalanceEnd = result.toNumber()
										return token.pause().then(()=> {
											return token.transfer(second, amount / 2, {from: crowdsale}).then(()=> {
												return token.balanceOf(second).then(result => {
													secondBalanceEnd = result
													return token.balanceOf(crowdsale).then(result => {
														crowdsaleBalanceEnd = result
														assert.equal(firstBalanceEnd, firstBalanceStart - amount)
														assert.equal(secondBalanceEnd, secondBalanceStart + (amount/2) )
														assert.equal(crowdsaleBalanceEnd, crowdsaleBalanceStart + (amount/2) )
													})
												})
											})
										})
									})
								})
							})
						})
					})
				})
			})
		})
	})

	it('Не должен отрабатывать, если не хватает средств', () => {
		var token, firstAmount;
		var first = accounts[0];
		var second = accounts[1];

		return Token.deployed().then(instance => {
			token = instance;
			return token.unpause().then(result => {
				return token.balanceOf(first).then(result => {
					firstAmount = result
					return token.transfer(second, firstAmount + 1, {from: first}).then(()=>
						assert.throw('Не должен давать перевести токены'),
						e => assert.isAtLeast(e.message.indexOf('Invalid array length'), 0)
					)
				})
			})
		})
	})
})

contract('Token.transferFrom', function(accounts) {
	it('Должен отрабатывать, если есть права на перевод такого количества средств', () => {

		var token,
			firstBalanceStart,
			firstBalanceEnd,
			secondBalanceStart,
			secondBalanceEnd


		var first = accounts[0]
		var second = accounts[1]
		var third = accounts[2]
		var amount = 100

		return Token.deployed().then(instance => {
			token = instance;
			return token.balanceOf(first).then(result => {
				firstBalanceStart = result.toNumber()
				return token.balanceOf(second).then(result => {
					secondBalanceStart = result.toNumber()
					return token.unpause().then(result => {
						return token.approve(third, amount, {from: first}).then(()=> {
							token.transferFrom(first, second, amount, {from: third}).then(()=> {
								return token.balanceOf(first).then(result => {
									firstBalanceEnd = result.toNumber()
									return token.balanceOf(second).then(result => {
										secondBalanceEnd = result.toNumber()
										assert.equal(firstBalanceEnd, firstBalanceStart - amount)
										assert.equal(secondBalanceEnd, secondBalanceStart + amount)
									})
								})
							})
						})
					})
				})
			})
		})
	})

	it('Не должен отрабатывать, если нет прав на перевод такого количества средств', () => {

		var token
		var first = accounts[0]
		var second = accounts[1]
		var third = accounts[2]
		var amount = 100
		var allowanceStart, allowanceEnd

		return Token.deployed().then(instance => {
			token = instance;
			return token.allowance(first, third).then(result => {
				allowanceStart = result.toNumber()
				return token.approve(third, amount, {from: first}).then(()=> {
					return token.allowance(first, third).then(result => {
						allowanceEnd = result.toNumber()
						return token.transferFrom(first, second, amount*2, {from: third})
						.then(assert.fail)
						.catch(e => assert(true))
					})
				})
			})
		})
	})
})

contract('Token.approve, Token.allowance', function(accounts) {
	it('Должен отрабатывать, если есть права на перевод такого количества средств', () => {

		var token, allowance

		var first = accounts[0]
		var second = accounts[1]
		var amount = 5000

		return Token.deployed().then(instance => {
			token = instance;
			return token.approve(second, amount, {from: first}).then(() => {
				return token.allowance(first, second).then(result => {
					allowance = result.toNumber()
					assert.equal(amount, allowance, 'Реальные и делегированные права на перевод токенов не совпадают')
				})
			})
		})
	})
})

contract('Token.increaseApproval, Token.decreaseApproval', function(accounts) {
	it('Должен увеличивать и правильно снижать количество токенов для распоряжения', async () => {

		const token = await Token.deployed()

		const amount = 1000
		const first = accounts[0]
		const second = accounts[1]

		let allowanceStart = await token.allowance(first, second)
		allowanceStart = allowanceStart.toNumber()

		await token.increaseApproval(second, amount)

		let allowanceIncreased = await token.allowance(first, second)
		allowanceIncreased = allowanceIncreased.toNumber()

		assert.equal(allowanceIncreased, allowanceStart + amount, 'увеличенное количество не совпадает')

		await token.decreaseApproval(second, amount/2)

		let allowanceDecreased = await token.allowance(first, second)
		allowanceDecreased = allowanceDecreased.toNumber()

		assert.equal(allowanceDecreased, allowanceIncreased - (amount/2), 'сниженное количество не совпадает')

		await token.decreaseApproval(second, amount*2)

		let allowanceEnd = await token.allowance(first, second)
		allowanceEnd = allowanceEnd.toNumber()

		assert.equal(allowanceEnd, 0, 'сниженное больше 0 не равно нулю')
	})
})

contract('Token.burn', function(accounts) {
	it('Должен сжигать токены со счета отправителя и вычитать их из totalSupply', async () => {

		const token = await Token.deployed()
		const burner = accounts[0]
		const amount = 100

		let totalSupplyStart = await token.totalSupply()
		totalSupplyStart = totalSupplyStart.toNumber()

		let burnerBalanceStart = await token.balanceOf(burner)
		burnerBalanceStart = burnerBalanceStart.toNumber()

		await token.burn(amount, {from: burner})

		let totalSupplyEnd = await token.totalSupply()
		totalSupplyEnd = totalSupplyEnd.toNumber()

		let burnerBalanceEnd = await token.balanceOf(burner)
		burnerBalanceEnd = burnerBalanceEnd.toNumber()


		assert.equal(burnerBalanceEnd, burnerBalanceStart - amount, 'сожглись не все токены')
		assert.equal(totalSupplyEnd, totalSupplyStart - amount, 'токены не вычлись из totalSupply')
	})
})

contract('Token.setSaleAddress', function(accounts) {
	it('Должен добавлять новый этап ICO', async () => {

		const token = await Token.deployed()
		const owner = accounts[0]
		const crowdsaleAddress = accounts[1]

		await token.setSaleAddress(crowdsaleAddress)

		const isSaleAgent = await token.saleAgents(crowdsaleAddress) // переменная нигде не объявлена и используется один раз???

		assert(isSaleAgent, 'saleAgent не добавился')
	})

	it('Должен добавлять только если вызвал owner', async () => {

		const token = await Token.deployed()
		const crowdsale = accounts[1]
		const notOwner = accounts[2]

		token.setSaleAddress(crowdsale, {from: notOwner})
		.then(assert.fail)
		.catch(e => assert(true))
	})
})

contract('Token.unpause, Token.pause', function(accounts) {
	it('Должен включать перевод токенов', async () => {

		const token = await Token.deployed()
		await token.unpause()
		const paused = await token.paused() // как возвращать true/false

		assert(paused = true, 'перевод токенов не включился')
	})

	it('Должен выключать перевод токенов', async () => {

		const token = await Token.deployed()
		await token.pause()
		const paused = await token.isEnabled()

		assert(!paused, 'перевод токенов не выключился')
	})

	it('Должен падать, если вызвал не owner', async () => {

		const token = await Token.deployed()
		const notOwner = accounts[1]

		token.unpause({from: notOwner})
		.then(assert.fail)
		.catch(e => assert(true))
	})
})