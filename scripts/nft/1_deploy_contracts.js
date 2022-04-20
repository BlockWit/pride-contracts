const NFT = artifacts.require('PrideNFT');
const NFTMarket = artifacts.require('NFTMarket');
const NFTMinter = artifacts.require('NFTMinter');
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
