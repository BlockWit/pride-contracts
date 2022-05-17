const NFT = artifacts.require('PrideNFT');
const NFTMarket = artifacts.require('NFTMarket');
const NFTMinter = artifacts.require('NFTMinter');
const { logger } = require('../util');

async function deploy () {
  const {log} = logger(await web3.eth.net.getNetworkType());
  const [deployer] = await web3.eth.getAccounts();

  const args = process.argv.slice(2);
  const NFT_ADDRESS = args[args.findIndex(argName => argName === '--nft') + 1];
  const MARKET_ADDRESS = args[args.findIndex(argName => argName === '--market') + 1];
  const MINTER_ADDRESS = args[args.findIndex(argName => argName === '--minter') + 1];

  const nft = await NFT.at(NFT_ADDRESS);
  const market = await NFTMarket.at(MARKET_ADDRESS);
  const minter = await NFTMinter.at(MINTER_ADDRESS);

  {
    log(`NFT. Set base URI.`);
    const tx = await nft.setBaseURI("htpps://nomadexiles.io/getNftData=", {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Minter. Set token address.`);
    const tx = await minter.setToken(NFT_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Minter. Set market address.`);
    const tx = await minter.setMarket(MARKET_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Market. Set token address.`);
    const tx = await market.setTokenAddress(NFT_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Market. Set minter address.`);
    const tx = await market.setMinterAddress(MINTER_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Market. Set fundraising wallet.`);
    const tx = await market.setFundraisingWallet(deployer, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`Token. Grant minter role to Minter.`);
    const tx = await nft.grantRole(web3.utils.keccak256("MINTER_ROLE"), MINTER_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

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