const NFT = artifacts.require('PrideNFT');
const NFTMarket = artifacts.require('NFTMarket');
const NFTMinter = artifacts.require('NFTMinter');
const NFTHolder = artifacts.require('NFTHolder');
const PricingController = artifacts.require('PricingController');
const SimpleNFTMinter = artifacts.require('SimpleNFTMinter');
const AccessController = artifacts.require('AccessController');
const { logger } = require('../util');

async function deploy () {
  const { log } = logger(await web3.eth.net.getNetworkType());
  const [deployer] = await web3.eth.getAccounts();

  const nft = await NFT.new({ from: deployer });
  log(`NFT deployed: @address{${nft.address}}`);

  const market = await NFTMarket.new({ from: deployer });
  log(`Market deployed: @address{${market.address}}`);

  const minter = await NFTMinter.new({ from: deployer });
  log(`Minter deployed: @address{${minter.address}}`);

  const pricing = await PricingController.new({ from: deployer });
  log(`PricingController deployed: @address{${pricing.address}}`);

  const access = await AccessController.new({ from: deployer });
  log(`AccessController deployed: @address{${access.address}}`);

  const holder = await NFTHolder.new({ from: deployer });
  log(`Holder deployed: @address{${holder.address}}`);

  const simpleMinter = await SimpleNFTMinter.new({ from: deployer });
  log(`SimpleNFTMinter deployed: @address{${simpleMinter.address}}`);

}

module.exports = async function main (callback) {
  try {
    await deploy();
    console.log('success');
    callback(null);
  } catch (e) {
    console.log('error');
    console.log(e);
    callback(e);
  }
};
