const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, time, ether } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const PricingController = contract.fromArtifact('PricingController');

const [owner] = accounts;

describe('PricingController', async () => {

  let pricingController;
  let strategy;

  beforeEach(async () => {
    pricingController = await PricingController.new({ from: owner });
    const start = (await time.latest()).add(time.duration.hours(1));
    strategy = {
      start,
      intervals: [time.duration.hours(3), time.duration.hours(6), time.duration.hours(6), time.duration.hours(6)],
      priceStep: ether('50')
    };
    await pricingController.setPricingStrategy(0, strategy.start, strategy.intervals, strategy.priceStep, { from: owner });
  });

  describe('calculatePrice', () => {
    it('should return price increased according to pricing strategy', async () => {
      const { start, intervals, priceStep } = strategy;
      const price = ether('123456');
      const item = [1, price, 0, 0];
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

});
