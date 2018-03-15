import ether from 'zeppelin-solidity/test/helpers/ether.js';
import advanceToBlock from 'zeppelin-solidity/test/helpers/advanceToBlock.js'
import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';

const WhalesburgToken = artifacts.require("WhalesburgToken");
const WhalesburgPreSale = artifacts.require("WhalesburgPreSale");
const WhalesburgRefundVault = artifacts.require("WhalesburgRefundVault");

const softCap = 62500;
const hardCap = 146250;
const ethUsdPrice = 78000;
const wallet = web3.eth.accounts[5];

contract('WhalesburgPreSale', function(accounts) {
  beforeEach(async function () {
    this.token = await WhalesburgToken.new();

    this.startBlock = web3.eth.blockNumber + 1;
    this.endBlock = this.startBlock + 15;

    this.preSale = await WhalesburgPreSale.new(
      this.startBlock,
      this.endBlock,
      this.token.address,
      softCap,
      hardCap,
      ethUsdPrice,
      wallet
    );

    const v = await this.preSale.vault();
    this.vault = WhalesburgRefundVault.at(v);
    await this.token.setTransferAgent(this.token.address, true);
    await this.token.setTransferAgent(this.preSale.address, true);
    await this.token.setTransferAgent(accounts[0], true);

    await this.token.transfer(this.preSale.address, ether(hardCap + 100));
  });

  it('should allow pause by owner', async function () {
    await this.preSale.pause();

    const paused = await this.preSale.paused();

    assert.equal(paused, true);
  });

  it('should not allow pause by not owner', async function () {
    try {
      await this.preSale.pause({from: accounts[1]});
      assert.fail('should have thrown before');
    } catch (error) {
      return assertRevert(error);
    }
  });

  it('should not allow to buy tokens when contract is paused', async function () {
    await this.preSale.pause();

    try {
      await this.preSale.sendTransaction({value: ether(1), from: accounts[1]});
      assert.fail('should have thrown before');
    } catch(error) {
      return assertRevert(error);
    }
  });

  it('should be possible to unpause token sale', async function () {
    await this.preSale.pause();

    try {
      await this.preSale.sendTransaction({value: ether(1), from: accounts[1]});
      assert.fail('should have thrown before');
    } catch(error) {
      return assertRevert(error);
    }

    this.preSale.unpause();

    await this.preSale.sendTransaction({value: ether(1), from: accounts[1]});

  });

  it ('should be possible to buy token', async function () {
    await this.preSale.sendTransaction({value: ether(1), from: accounts[1]});

    const balance = await this.token.balanceOf(accounts[1]);
    const tokensSold = await this.preSale.tokensSold();
    const vault = await this.preSale.vault();
    const vaultBalance = web3.eth.getBalance(vault);
    const deposited = await this.vault.depositOf(accounts[1]);

    assert.equal(balance.toNumber(), ether(16250).toNumber());
    assert.equal(tokensSold.toNumber(), ether(16250).toNumber());
    assert.equal(vaultBalance.toNumber(), ether(1).toNumber());
    assert.equal(deposited.toNumber(), ether(1).toNumber());
  });

  it('should make vault#withdraw possible when softCapReached', async function () {
    await this.preSale.sendTransaction({value: ether(4), from: accounts[1]});

    const softCapReached = await this.preSale.softCapReached();
    const vaultSoftCapReached = await this.vault.softCapReached();
    assert.equal(softCapReached, true);
    assert.equal(vaultSoftCapReached, true);

    const balanceBefore = web3.eth.getBalance(accounts[5]);

    await this.vault.withdraw(ether(2), {from: accounts[5]});

    const balanceAfter = web3.eth.getBalance(accounts[5]);
    assert.equal(balanceAfter > balanceBefore, true);
  });

  it('should not be possible to finalize sale until endBlock', async function () {
    assert.equal(web3.eth.blockNumber < this.endBlock, true);

    try {
      await this.preSale.finalize();
      assert.fail('should have thrown before');
    } catch (error) {
      return assertRevert(error);
    }
  });

  it('should be possible to refund ether from vault if softCap was not reached', async function () {
    await this.preSale.sendTransaction({value: ether(1), from: accounts[1]});

    const balanceBefore = web3.eth.getBalance(accounts[1]);

    await advanceToBlock(this.endBlock + 1);
    await this.preSale.finalize();
    await this.preSale.claimRefund({from: accounts[1]});

    const vault = await this.preSale.vault();
    const vaultBalance = web3.eth.getBalance(vault);
    const balanceAfter = web3.eth.getBalance(accounts[1]);
    const deposited = await this.vault.depositOf(accounts[1]);

    assert.equal(balanceAfter > balanceBefore, true);
    assert.equal(deposited, 0);
  });

  it('should be impossibe to claimRefnud whlile token sale is active', async function () {
    try {
      await this.preSale.claimRefund();
      assert.fail('should have thrown before');
    } catch (error) {
      return assertRevert(error);
    }

  });

  it('should be impossible to send more than hardcap', async function () {
    try {
      await this.preSale.sendTransaction({value: ether(50), from: accounts[2]});
      assert.fail('should have thrown before');
    } catch (error) {
      return assertRevert(error);
    }
  });

  it('should be possible to finalize contract when hardCap was reached', async function () {
    await this.preSale.sendTransaction({value: ether(9), from: accounts[3]});
    await this.preSale.finalize();
    const finalized = await this.preSale.isFinalized();

    assert.equal(finalized, true);
  });

  it('should burn unsold tokens if hardcap not reached', async function () {
    await this.preSale.sendTransaction({value: ether(4), from: accounts[4]});

    const totalSupplyBefore = await this.token.totalSupply();
    const balance = await this.token.balanceOf(accounts[4]);

    await advanceToBlock(this.endBlock + 1);
    await this.preSale.finalize();

    const totalSupply = await this.token.totalSupply();

    assert.equal(totalSupply.toNumber(), totalSupplyBefore.toNumber() - ether(hardCap + 100).toNumber()+ balance.toNumber()); // substract excessive tokens, which were added to test hard cap
  });
})
