const AccessController = artifacts.require('AccessController');
const PricingController = artifacts.require('PricingController');
const { logger } = require('../util');

async function deploy () {
  const {log} = logger(await web3.eth.net.getNetworkType());
  const [deployer] = await web3.eth.getAccounts();

  const args = process.argv.slice(2);
  const ACCESS_CONTROLLER_ADDRESS = args[args.findIndex(argName => argName === '--access') + 1];
  const PRICING_CONTROLLER_ADDRESS = args[args.findIndex(argName => argName === '--pricing') + 1];

  const accessController = await AccessController.at(ACCESS_CONTROLLER_ADDRESS);
  const pricingController = await PricingController.at(PRICING_CONTROLLER_ADDRESS);

  {
    log(`AccessController. Give access to all accounts.`);
    const tx = await accessController.setAccessLevel(0, 0, 1972069200, { from: deployer });
    log(`Result: successful tx: @tx{${tx.receipt.transactionHash}}`);
  }

  {
    log(`PricingController. Add pricing strategy.`);
    const tx = await pricingController.setPricingStrategy(0, 0, [0], 0, { from: deployer });
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
