import { ethers } from 'ethers';
import { parseEther } from 'ethers/lib/utils';

const ERC20_ABI = [
  'function totalSupply() external view returns (uint256)',
  'function balanceOf(address account) external view returns (uint256)',
  'function transfer(address recipient, uint256 amount) external returns (bool)',
  'function allowance(address owner, address spender) external view returns (uint256)',
  'function approve(address spender, uint256 amount) external returns (bool)'
];

const ERC20_ADDRESS = '0x7279F00ed15244fc0d97e35B463802Fc501C3811';

export const erc20ContractFromProvider = (web3provider) => {
  return new ethers.Contract(ERC20_ADDRESS, ERC20_ABI, web3provider);
};

export async function approve(web3Provider, to, amount) {
  const erc20Contract = erc20ContractFromProvider(web3Provider);
  const signer = web3Provider.getSigner();
  const contractWithSigner = erc20Contract.connect(signer);
  return await contractWithSigner.approve(to, parseEther(amount));
}

export async function balanceOf (web3Provider, account) {
  const erc20Contract = erc20ContractFromProvider(web3Provider);
  return await erc20Contract.balanceOf(account);
}
