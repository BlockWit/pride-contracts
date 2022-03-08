const Configurator = artifacts.require('Configurator');
const Token = artifacts.require('PrideToken');
const TokenDepositor = artifacts.require('TokenDepositor');
const Wallet = artifacts.require('VestingWallet');
const { logger } = require('./util');

async function deploy () {
  const { log } = logger(await web3.eth.net.getNetworkType());
  const [deployer] = await web3.eth.getAccounts();

  const configurator = await Configurator.new({ from: deployer });
  log(`Configurator deployed: @address{${configurator.address}}`);

  const wallet = await Wallet.new({ from: deployer });
  log(`Wallet deployed: @address{${wallet.address}}`);

  const depositor = await TokenDepositor.new({ from: deployer });
  log(`Depositor deployed: @address{${depositor.address}}`);

  const token = await Token.new({ from: deployer });
  log(`Token deployed: @address{${token.address}}`);

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
