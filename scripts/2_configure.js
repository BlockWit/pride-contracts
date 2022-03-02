const Configurator = artifacts.require('Configurator');
const Token = artifacts.require('PrideToken');
const TokenDepositor = artifacts.require('TokenDepositor');
const Sale = artifacts.require('CrowdSale');
const Wallet = artifacts.require('VestingWallet');
const { logger } = require('./util');

async function deploy () {
  const args = process.argv.slice(2);
  const CONFIGURATOR_ADDRESS = args[args.findIndex(argName => argName === '--configurator') + 1];
  const SALE_ADDRESS = args[args.findIndex(argName => argName === '--sale') + 1];
  const TOKEN_ADDRESS = args[args.findIndex(argName => argName === '--token') + 1];
  const DEPOSITOR_ADDRESS = args[args.findIndex(argName => argName === '--depositor') + 1];
  const WALLET_ADDRESS = args[args.findIndex(argName => argName === '--wallet') + 1];

  const { log } = logger(await web3.eth.net.getNetworkType());
  const [deployer] = await web3.eth.getAccounts();

  const configurator = await Configurator.at(CONFIGURATOR_ADDRESS);
  const sale = await Sale.at(SALE_ADDRESS);
  const token = await Token.at(TOKEN_ADDRESS);
  const depositor = await TokenDepositor.at(DEPOSITOR_ADDRESS);
  const wallet = await Wallet.at(WALLET_ADDRESS)

  {
    log(`Token. Transfer ownership.`);
    const tx = await token.transferOwnership(CONFIGURATOR_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }
  {
    log(`CrowdSale. Transfer ownership.`);
    const tx = await sale.transferOwnership(CONFIGURATOR_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }
  {
    log(`Depositor. Transfer ownership.`);
    const tx = await depositor.transferOwnership(CONFIGURATOR_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }
  {
    log(`Wallet. Transfer ownership.`);
    const tx = await wallet.transferOwnership(CONFIGURATOR_ADDRESS, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }
  {
    log(`Token. Approve.`);
    const amount = await token.balanceOf(deployer);
    const tx = await token.approve(CONFIGURATOR_ADDRESS, amount, {from: deployer});
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }
  {
    log(`Configurator. Configure.`);
    const tx = await configurator.init(TOKEN_ADDRESS, WALLET_ADDRESS, SALE_ADDRESS, DEPOSITOR_ADDRESS, {from: deployer});
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
