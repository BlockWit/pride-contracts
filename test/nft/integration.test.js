const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { BN, ether, expectEvent, expectRevert, time, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const PrideNFT = contract.fromArtifact('PrideNFT');
const PrideToken = contract.fromArtifact('PrideToken');
const NFTHolder = contract.fromArtifact('NFTHolder');
const AccessController = contract.fromArtifact('AccessController');
const PricingController = contract.fromArtifact('PricingController');
const NFTMarket = contract.fromArtifact('NFTMarket');
const NFTMinter = contract.fromArtifact('NFTMinter');
const ERC20Mock = contract.fromArtifact('ERC20Mock');

const [owner, manager, fundraisingWallet, buyer1, buyer2] = accounts;

describe('Integration test', async () => {
  let nft;
  let pride;
  let holder;
  let accessController;
  let pricingController;
  let market;
  let minter;
  let erc20mock;

  beforeEach(async () => {
    [ nft, pride, holder, accessController, pricingController, market, minter, erc20mock ] = await Promise.all([
      PrideNFT.new({ from: owner }),
      PrideToken.new({ from: owner }),
      NFTHolder.new({ from: owner }),
      AccessController.new({ from: owner }),
      PricingController.new({ from: owner }),
      NFTMarket.new({ from: owner }),
      NFTMinter.new({ from: owner }),
      ERC20Mock.new('BUSD', 'BUSD', owner, ether('10000'), { from: owner })
    ]);
    await Promise.all([
      pride.transfer(buyer1, ether('123'), { from: owner }),
      erc20mock.transfer(buyer1, ether('345'), { from: owner }),
    ]);
    await Promise.all([
      nft.grantRole(web3.utils.keccak256("MINTER_ROLE"), minter.address, {from: owner }),
      holder.setToken(nft.address, { from: owner }),
      holder.setApproval(market.address, true, { from: owner }),
      minter.setToken(nft.address, { from: owner }),
      minter.setMarket(market.address, { from: owner }),
      minter.setHolder(holder.address, { from: owner }),
      market.setFundraisingWallet(fundraisingWallet, { from: owner }),
      market.setPrideNFT(nft.address, { from: owner }),
      market.setPrideToken(pride.address, { from: owner }),
      market.setERC20(erc20mock.address, { from: owner }),
      market.setManager(minter.address, { from: owner }),
      market.setHolder(holder.address, { from: owner }),
      market.setAccessController(accessController.address, { from: owner }),
      market.setPricingController(pricingController.address, { from: owner }),
    ])
  });

  describe('NFTMinter', () => {
    it('mintAndAddToMarket should mint token and move it to holder address', async () => {
      await minter.mintAndAddToMarket([ether('1')], [0], [0], { from: owner });
      expect(await nft.balanceOf(holder.address)).to.be.bignumber.equal(new BN('1'));
    });
  });

  describe('NFTMarket', () => {
    beforeEach(async () => {
      await minter.mintAndAddToMarket([ether('123')], [0], [0], { from: owner });
      await minter.mintAndAddToMarket([ether('345')], [0], [1], { from: owner });
      await minter.mintAndAddToMarket([ether('0.678')], [0], [2], { from: owner });
      const now = await time.latest();
      await accessController.setAccessLevel(0, now, now.add(time.duration.years(1)), { from: owner });
      await pricingController.setPricingStrategy(0, now, [time.duration.hours(3)], ether('50'), { from: owner });
    });

    describe('buy', () => {
      describe('should sell tokens', () => {
        it('for PRIDE', async () => {
          await pride.approve(market.address, ether('123'), { from: buyer1 });
          await market.buy([0], { from: buyer1 });
          expect (await nft.balanceOf(buyer1)).to.be.bignumber.equal(new BN('1'));
        });
        it('for ERC20', async () => {
          await erc20mock.approve(market.address, ether('345'), { from: buyer1 });
          await market.buy([1], { from: buyer1 });
          expect (await nft.balanceOf(buyer1)).to.be.bignumber.equal(new BN('1'));
        });
        it('for native currency', async () => {
          await market.buy([2], { from: buyer1, value: ether('0.678') });
          expect (await nft.balanceOf(buyer1)).to.be.bignumber.equal(new BN('1'));
        });
      });
      describe('should transfer incoming assets to fundraising wallet', async () => {
        it('PRIDE', async () => {
          await pride.approve(market.address, ether('123'), { from: buyer1 });
          await market.buy([0], { from: buyer1 });
          expect (await pride.balanceOf(fundraisingWallet)).to.be.bignumber.equal(ether('123'));
        });
        it('ERC20', async () => {
          await erc20mock.approve(market.address, ether('345'), { from: buyer1 });
          await market.buy([1], { from: buyer1 });
          expect (await erc20mock.balanceOf(fundraisingWallet)).to.be.bignumber.equal(ether('345'));
        });
        it('Native currency', async () => {
          const amount = ether('0.678');
          const balanceBefore = await web3.eth.getBalance(fundraisingWallet);
          await market.buy([2], { from: buyer1, value: amount });
          const balanceAfter = await web3.eth.getBalance(fundraisingWallet);
          expect (new BN(balanceAfter).sub(new BN(balanceBefore))).to.be.bignumber.equal(amount);
        });
      });
    });

    describe('getMarketItems', () => {
      it('should return full list of market items', async () => {
        const items = await market.getMarketItems();
        expect(items.length).to.be.equal(3);
      });
    });

    describe('getMarketItemsWithPrices', () => {
      it('should return full information about market items', async () => {
        const items = await market.getMarketItemsWithPrices([0, 1, 3]);
        expect(items.length).to.be.equal(3);
      });
    });

    describe('getAccessTime', () => {
      let level0AccessTime;
      let level1AccessTime;

      beforeEach(async () => {
        const now = await time.latest();
        level0AccessTime = now.add(time.duration.hours(2));
        level1AccessTime = now.add(time.duration.hours(1));
        await accessController.setAccessLevel(0, level0AccessTime, level0AccessTime.add(time.duration.years(1)), { from: owner });
        await accessController.setAccessLevel(1, level1AccessTime, level1AccessTime.add(time.duration.hours(1)), { from: owner });
        await accessController.setAccountLevels([buyer1, buyer2], [0, 1], { from: owner });
      });
      describe('for non-zero address', () => {
        it('should return correct timestamp for users with access level 0', async () => {
          const timestamp = await market.getAccessTime(buyer1);
          expect(timestamp).to.be.bignumber.equal(level0AccessTime);
        });
        it('should return correct timestamp for users with access level 1', async () => {
          const timestamp = await market.getAccessTime(buyer2);
          expect(timestamp).to.be.bignumber.equal(level1AccessTime);
        });
      });
      describe('for zero address', () => {
        it('should return timestamp the same as for users with access level 0', async () => {
          const timestamp = await market.getAccessTime(constants.ZERO_ADDRESS);
          expect(timestamp).to.be.bignumber.equal(level0AccessTime);
        });
      });
    });
  });

});
