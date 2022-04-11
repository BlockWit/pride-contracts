import { ethers } from 'ethers';
import { useWallet } from 'use-wallet';

const NETWORK_NAME_ROPSTEN = 'ropsten';

const NETWORK_NAME_TESTNET = 'testnet';

const EXPLORER_NAME_BSCSCAN = '.bscscan.com';

const EXPLORER_NAME_ETHERSCAN = '.etherscan.io';

export const networkName = NETWORK_NAME_TESTNET;

export const explorerName = EXPLORER_NAME_BSCSCAN;

export const getWeb3FromWallet = (wallet) => {
  return new ethers.providers.Web3Provider(wallet.ethereum);
};

export const useWeb3 = () => {
  return getWeb3FromWallet(useWallet());
};
