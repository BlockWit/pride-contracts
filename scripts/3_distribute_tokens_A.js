const { ether } = require('@openzeppelin/test-helpers');
const { fromCSV, logger } = require('./util');

async function deploy () {
  const { log } = logger(await web3.eth.net.getNetworkType());
  {
    log(`Depositor. Private round 1. 3% unlocked.`);
    const unlocked = 3;
    const schedule = 1;
    const { addresses, balances } = fromCSV('distribution/private_round_1.csv');
    console.log(JSON.stringify([unlocked, schedule, addresses, balances.map(ether).map(b => b.toString())]))
  }
  {
    log(`Depositor. Private round 2. 4% unlocked.`);
    const unlocked = 4;
    const schedule = 2;
    const { addresses, balances } = fromCSV('distribution/private_round_2.csv');
    console.log(JSON.stringify([unlocked, schedule, addresses, balances.map(ether).map(b => b.toString())]))
  }
  {
    log(`Depositor. Private round 3. 5% unlocked.`);
    const unlocked = 5;
    const schedule = 3;
    const { addresses, balances } = fromCSV('distribution/private_round_3_2.csv');
    console.log(JSON.stringify([unlocked, schedule, addresses, balances.map(ether).map(b => b.toString())]))
  }
  {
    log(`Distributor. Public sale.`);
    const { addresses, balances } = fromCSV('distribution/public_sale_2.csv');
    console.log(JSON.stringify([addresses, balances.map(ether).map(b => b.toString())]))
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
