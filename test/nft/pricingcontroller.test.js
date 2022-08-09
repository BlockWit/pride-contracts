const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, time, ether, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const PricingController = contract.fromArtifact('PricingController');

const [owner, user] = accounts;

describe('PricingController', async () => {

  let pricingController;
  let strategy;

  beforeEach(async () => {
    pricingController = await PricingController.new({ from: owner });
  });

  describe('calculatePrice', () => {
    beforeEach(async () => {
      const start = (await time.latest()).add(time.duration.hours(1));
      strategy = {
        start,
        intervals: [time.duration.hours(3), time.duration.hours(6), time.duration.hours(6), time.duration.hours(6)],
        priceStep: ether('50')
      };
      await pricingController.setPricingStrategy(0, strategy.start, strategy.intervals, strategy.priceStep, { from: owner });
    });
    it('should return price increased according to pricing strategy', async () => {
      const { start, intervals, priceStep } = strategy;
      const price = ether('123456');
      const item = [price, 0, 0];
      {
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price);
      }
      {
        await time.increaseTo(start.add(intervals[0]).add(time.duration.seconds(1)));
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price.add(priceStep));
      }
      {
        await time.increaseTo(start.add(intervals[0]).add(intervals[1]).add(time.duration.seconds(1)));
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price.add(priceStep).add(priceStep));
      }
      {
        await time.increaseTo(start.add(intervals[0]).add(intervals[1]).add(intervals[2]).add(time.duration.seconds(1)));
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price.add(priceStep).add(priceStep).add(priceStep));
      }
      {
        await time.increaseTo(start.add(intervals[0]).add(intervals[1]).add(intervals[2]).add(intervals[3]).add(time.duration.seconds(1)));
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price.add(priceStep).add(priceStep).add(priceStep).add(priceStep));
      }
      {
        await time.increaseTo(start.add(intervals[0]).add(intervals[1]).add(intervals[2]).add(intervals[3]).add(time.duration.years(1)));
        const result = await pricingController.calculatePrice(item);
        expect(result).to.be.bignumber.equal(price.add(priceStep).add(priceStep).add(priceStep).add(priceStep));
      }
    });
  });
  describe('setPricingStrategy', () => {
    it('should revert whten called by non-admin', async () => {
      const strategy = { start: 0, intervals: [], priceStep: 0};
      await expectRevert(pricingController.setPricingStrategy(0, strategy.start, strategy.intervals, strategy.priceStep, { from: user }), 'missing role');
    });
    it('should add new pricing strategy for non-existent key', async () => {
      const strategy = { start: 0, intervals: [], priceStep: 0};
      let keys = await pricingController.getPricingStrategyKeys();
      expect(keys.length).to.be.equal(0);
      await pricingController.setPricingStrategy(0, strategy.start, strategy.intervals, strategy.priceStep, { from: owner });
      keys = await pricingController.getPricingStrategyKeys();
      expect(keys.length).to.be.equal(1);
    });
    it('should update existing strategy', async () => {
      let strategy = {key: 0, start: 0, intervals: [], priceStep: 0};
      await pricingController.setPricingStrategy(strategy.key, strategy.start, strategy.intervals, strategy.priceStep, { from: owner });
      let [key] = await pricingController.getPricingStrategyKeys();
      strategy = {key, start: 1, intervals: [], priceStep: 1};
      await pricingController.setPricingStrategy(strategy.key, strategy.start, strategy.intervals, strategy.priceStep, { from: owner });
      const [ start, intevals, priceStep ] = await pricingController.getPricingStrategy(key);
      expect(start).to.be.equal('1');
      expect(priceStep).to.be.equal('1');
    });
  });
  describe('removePricingStrategy', () => {
    beforeEach(async () => {
      const strategies = [
        {key: 0, start: 0, intervals: [], priceStep: 0},
        {key: 1, start: 1, intervals: [], priceStep: 1},
        {key: 2, start: 2, intervals: [], priceStep: 2}
      ];
      await Promise.all(strategies.map(({key, start, intervals, priceStep}) => pricingController.setPricingStrategy(key, start, intervals, priceStep, { from: owner })));
    });
    it('should remove pricing strategy', async () => {
      let keys = await pricingController.getPricingStrategyKeys();
      expect(keys.length).to.be.equal(3);
      await pricingController.removePricingStrategy(1, {from: owner});
      keys = await pricingController.getPricingStrategyKeys();
      expect(keys.length).to.be.equal(2);
      await expectRevert(pricingController.getPricingStrategy(1), 'nonexistent key')
    });
  });

});
