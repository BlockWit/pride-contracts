const { dateFromNow, getEvents, getTransactionCost, increaseDateTo } = require('./util');
const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { BN, ether, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const Token = contract.fromArtifact('PrideToken');
const BUSD = contract.fromArtifact('ERC20Mock');
const Sale = contract.fromArtifact('CrowdSale');
const Wallet = contract.fromArtifact('VestingWallet');

const [deployer, owner, fundraisingWallet, buyer] = accounts;
const PRICE = 10000;

describe('CrowdSale', async function () {
  let token;
  let busd;
  let sale;
  let wallet;
  let STAGES;

  beforeEach(async function () {
    this.timeout(0);
    STAGES = [
      { start: await dateFromNow(1), end: await dateFromNow(8), bonus: 100, minInvestmentLimit: ether('0.03'), hardcap: ether('80000'), whitelist: false },
      { start: await dateFromNow(9), end: await dateFromNow(16), bonus: 0, minInvestmentLimit: ether('0.03'), hardcap: ether('120000'), whitelist: false }
    ];
    sale = await Sale.new({ from: deployer });
    token = await Token.new({ from: deployer });
    busd = await BUSD.new('BUSD', 'BUSD', deployer, ether('1000000'), { from: deployer });
    wallet = await Wallet.new({ from: deployer });
    await Promise.all([
      wallet.setToken(token.address, { from: deployer }),
      sale.setToken(token.address, { from: deployer }),
      sale.setBUSD(busd.address, { from: deployer }),
      sale.setFundraisingWallet(fundraisingWallet, { from: deployer }),
      sale.setVestingWallet(wallet.address, { from: deployer }),
      sale.setPrice(ether(PRICE.toString()), { from: deployer }),
      token.transfer(sale.address, ether('300000000'), { from: deployer })
    ]);
    const users = [deployer, ...accounts];
    await Promise.all(users.map(user => busd.transfer(user, ether('1000000').divn(accounts.length), { from: deployer })))
    await Promise.all(STAGES.map((stage, i) => {
      const { start, end, bonus, minInvestmentLimit, hardcap, whitelist } = stage;
      return sale.setStage(i, start, end, bonus, minInvestmentLimit, hardcap, 0, 0, 0, 0, whitelist, { from: deployer });
    }));
    await Promise.all([
      sale.transferOwnership(owner, { from: deployer }),
      token.transferOwnership(owner, { from: deployer }),
      wallet.transferOwnership(owner, { from: deployer })
    ]);
  });

  it('should not accept BUSD before crowdsale start', async function () {
    await busd.approve(sale.address, ether('1'), { from: buyer });
    await expectRevert(sale.buy(ether('1'), { from: buyer }), 'CrowdSale: No suitable stage found');
  });

  it('should not accept BUSD below min limit', async function () {
    await increaseDateTo(STAGES[0].start);
    await busd.approve(sale.address, ether('0.029'), { from: buyer });
    await expectRevert(sale.buy(ether('0.029'), { from: buyer }), 'CrowdSale: The amount of BUSD is too small.');
  });

  it('should accept BUSD above min limit', async function () {
    const { start, bonus } = STAGES[0];
    await increaseDateTo(start);
    const busdSent = ether('0.1');
    await busd.approve(sale.address, busdSent, { from: buyer });
    const { tx } = await sale.buy(busdSent, { from: buyer });
    const [{args: {value: tokensReceived}}] = await getEvents(tx, token, 'Transfer', web3);
    const tokensExpected = busdSent.muln(PRICE).muln(100 + bonus).divn(100);
    expect(tokensReceived).to.be.bignumber.equal(tokensExpected);
  });

  it('should not return tokens above the hardcap', async function () {
    const { start, hardcap } = STAGES[0];
    await increaseDateTo(start);
    const busdSent = ether('99');
    await busd.approve(sale.address, busdSent, { from: buyer });
    const { tx } = await sale.buy(busdSent, { from: buyer });
    const [{args: {value: tokensReceived}}] = await getEvents(tx, token, 'Transfer', web3);
    expect(tokensReceived).to.be.bignumber.equal(hardcap);
  });

  it('should transfer correct amount of BUSD', async function () {
    const { start, bonus, hardcap } = STAGES[0];
    await increaseDateTo(start);
    const busdApproved = ether('123000');
    await busd.approve(sale.address, busdApproved, { from: buyer });
    const busdBalanceBefore = await busd.balanceOf(buyer);
    await sale.buy(busdApproved, { from: buyer });
    const tokensPerBUSD = PRICE * (100 + bonus) / 100;
    const busdTransfered = hardcap.divn(tokensPerBUSD);
    const busdBalanceAfter = await busd.balanceOf(buyer);
    expect(busdBalanceAfter).to.be.bignumber.equal(busdBalanceBefore.sub(busdTransfered));
  });

  it('should not accept BUSD between crowdsale stages', async function () {
    await increaseDateTo(STAGES[0].end);
    const busdSent = ether('99');
    await busd.approve(sale.address, busdSent, { from: buyer });
    await expectRevert(sale.buy(busdSent, { from: buyer }), 'CrowdSale: No suitable stage found');
  });

  it('should accept BUSD after the start of the next stage', async function () {
    const { start, bonus } = STAGES[1];
    await increaseDateTo(start);
    const busdSent = ether('0.123');
    await busd.approve(sale.address, busdSent, { from: buyer });
    const { receipt: { transactionHash } } = await sale.buy(busdSent, { from: buyer });
    const events = await getEvents(transactionHash, token, 'Transfer', web3);
    const tokensExpected = busdSent.muln(PRICE * (100 + bonus) / 100);
    const tokensReceived = new BN(events[0].args.value);
    expect(tokensReceived).to.be.bignumber.equal(tokensExpected);
  });

  it('should distribute tokens between stages correctly when unlockedOnTGE > 0', async function () {
    const { start, end, bonus, minInvestmentLimit, hardcap } = STAGES[1];
    const vestingSchedule = 1;
    const unlockedOnTGE = 10;
    const whitelist = false;
    await sale.setStage(1, start, end, bonus, minInvestmentLimit, hardcap, vestingSchedule, unlockedOnTGE, 0, 0, whitelist, { from: owner });
    await increaseDateTo(start);
    const busdSent = ether('0.123');
    await busd.approve(sale.address, busdSent, { from: buyer });
    await sale.buy(busdSent, { from: buyer });
    const {initial: unlocked} = await wallet.balances(0, buyer);
    const {initial: locked} = await wallet.balances(1, buyer);
    expect(unlocked).to.be.bignumber.equal(unlocked.add(locked).muln(unlockedOnTGE).divn(100));
  });

  it('should remove stage by index correctly', async function () {
    await sale.removeStage(0, { from: owner });
    const stage1 = await sale.getStage(1);
    expectStageToBeEqual(stage1, STAGES[1]);
    await expectRevert(sale.getStage(0), 'Stages.Map: nonexistent key');
  });

  describe('whitelist', function () {
    it('should not be editable by non-owner', async function () {
      await expectRevert(sale.addToWhitelist([buyer], {from: buyer}), 'Ownable: caller is not the owner');
      await expectRevert(sale.removeFromWhitelist([buyer], {from: buyer}), 'Ownable: caller is not the owner');
    });
    it('should be editable by the owner', async function () {
      await sale.addToWhitelist([buyer], {from: owner});
      expect(await sale.whitelist(buyer)).to.be.equal(true);
      await sale.removeFromWhitelist([buyer], {from: owner});
      expect(await sale.whitelist(buyer)).to.be.equal(false);
    });
    it('should not allow non-whitelisted users to buy tokens', async function () {
      const { start, end, bonus, minInvestmentLimit, hardcap } = STAGES[0];
      await sale.setStage(0, start, end, bonus, minInvestmentLimit, hardcap, 0, 0, 0, 0, true, { from: owner });
      await increaseDateTo(start);
      await busd.approve(sale.address, ether('1'), { from: buyer });
      await expectRevert(sale.buy(ether('1'), { from: buyer }), 'CrowdSale: Caller is not whitelisted');
    })
    it('should allow whitelisted users to buy tokens', async function () {
      const { start, end, bonus, minInvestmentLimit, hardcap } = STAGES[0];
      await sale.setStage(0, start, end, bonus, minInvestmentLimit, hardcap, 0, 0, 0, 0, true, { from: owner });
      await sale.addToWhitelist([buyer], {from: owner});
      await increaseDateTo(start);
      await busd.approve(sale.address, ether('0.123'), { from: buyer });
      const { tx } = await sale.buy(ether('0.123'), { from: buyer });
      const [{args: {value}}] = await getEvents(tx, token, 'Transfer', web3);
      expect(value).to.be.bignumber.gt(new BN('0'));
    })
  })
});

function expectStageToBeEqual (actual, expected) {
  expect(actual.start).to.be.bignumber.equal(new BN(expected.start));
  expect(actual.end).to.be.bignumber.equal(new BN(expected.end));
  expect(actual.bonus).to.be.bignumber.equal(new BN(expected.bonus));
  expect(actual.minInvestmentLimit).to.be.bignumber.equal(expected.minInvestmentLimit);
  expect(actual.hardcapInTokens).to.be.bignumber.equal(expected.hardcap);
}
