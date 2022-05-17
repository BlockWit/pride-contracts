const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { BN, ether, expectEvent, expectRevert, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const PrideNFT = contract.fromArtifact('PrideNFT');
const PrideToken = contract.fromArtifact('PrideToken');
const NFTHolder = contract.fromArtifact('NFTHolder');
const NFTMarket = contract.fromArtifact('NFTMarket');
const NFTMinter = contract.fromArtifact('NFTMinter');
const ERC20Mock = contract.fromArtifact('ERC20Mock');

const [owner, manager, fundraisingWallet, buyer] = accounts;

describe('NFT', async () => {
  let nft;
  let pride;
  let holder;
  let market;
  let minter;
  let erc20mock;

  beforeEach(async () => {
    [ nft, pride, holder, market, minter, erc20mock ] = await Promise.all([
      PrideNFT.new({ from: owner }),
      PrideToken.new({ from: owner }),
      NFTHolder.new({ from: owner }),
      NFTMarket.new({ from: owner }),
      NFTMinter.new({ from: owner }),
      ERC20Mock.new('BUSD', 'BUSD', owner, ether('10000'), { from: owner })
    ]);
    await Promise.all([
      pride.transfer(buyer, ether('123'), { from: owner }),
      erc20mock.transfer(buyer, ether('345'), { from: owner }),
    ]);
    await Promise.all([
      nft.grantRole(web3.utils.keccak256("MINTER_ROLE"), minter.address, {from: owner }),
      holder.setToken(nft.address, { from: owner }),
      holder.setApproval(market.address, true, { from: owner }),
      minter.setToken(nft.address, { from: owner }),
      minter.setMarket(market.address, { from: owner }),
      minter.setHolder(holder.address, { from: owner }),
      market.setFundraisingWallet(fundraisingWallet, { from: owner }),
      market.setNFT(nft.address, { from: owner }),
      market.setPride(pride.address, { from: owner }),
      market.setERC20(erc20mock.address, { from: owner }),
      market.setManager(minter.address, { from: owner }),
      market.setHolder(holder.address, { from: owner }),
    ])
  });

  describe('NFTMinter', () => {
    it('mintAndAddToMarket should mint token and move it to holder address', async () => {
      await minter.mintAndAddToMarket([ether('1')], [0], { from: owner });
      expect(await nft.balanceOf(holder.address)).to.be.bignumber.equal(new BN('1'));
    });
  });

  describe('NFTMarket', () => {
    beforeEach(async () => {
      await minter.mintAndAddToMarket([ether('123')], [0], { from: owner });
      await minter.mintAndAddToMarket([ether('345')], [1], { from: owner });
      await minter.mintAndAddToMarket([ether('0.678')], [2], { from: owner });
    });

    it('should sell tokens for PRIDE', async () => {
      await pride.approve(market.address, ether('123'), { from: buyer });
      await market.buyForERC20([0], { from: buyer });
      expect (await nft.balanceOf(buyer)).to.be.bignumber.equal(new BN('1'));
    });

    it('should sell tokens for ERC20', async () => {
      await erc20mock.approve(market.address, ether('345'), { from: buyer });
      await market.buyForERC20([1], { from: buyer });
      expect (await nft.balanceOf(buyer)).to.be.bignumber.equal(new BN('1'));
    });

    it('should sell tokens for native currency', async () => {
      await market.buy([2], { from: buyer, value: ether('0.678') });
      expect (await nft.balanceOf(buyer)).to.be.bignumber.equal(new BN('1'));
    });
  });


});
