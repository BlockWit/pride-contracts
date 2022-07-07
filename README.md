![Pride](logo.png "PRIDE Token")

# Pride smart contracts

* _Standart_        : [BEP20](https://github.com/binance-chain/BEPs/blob/master/BEP20.md)
* _[Name](https://github.com/binance-chain/BEPs/blob/master/BEP20.md#5111-name)_              : PRIDE Token
* _[Ticker](https://github.com/binance-chain/BEPs/blob/master/BEP20.md#5112-symbol)_          : PRIDE
* _[Decimals](https://github.com/binance-chain/BEPs/blob/master/BEP20.md#5113-decimals)_      : 18
* _Emission_        : One-time, 250 000 000 tokens
* _Fiat dependency_ : No
* _Token locks_     : Yes

## Smart contracts description

Pride smart-contract

### Contracts
1. _PrideToken_- Token contract
2. _VestingWallet_ - Wallet contract
3. _TokenDepositor_ - Helper contract for batch token distribution
4. _Configurator_ - Smart contract for initial configuration
5. _PrideNFT_ - NFT token contract
6. _NFTMinter_ - Helper contract for batch NFT minting
7. _NFTMarket_ - Smart contract for the initial sale of NFT tokens

### How to work with this project
#### To start working with the contracts, please, follow theese steps for each contract:
1. Compile the contract using Remix with `enable optimization` flag and `compiler version` set to `0.8.0`.
2. Copy `.env.example` to `.env` and fill in the parameters.
2. Deploy the contract using deployment script:  
   ```truffle exec scripts/1_deploy_configurator.js --network NetworkName```  
   for example:  
   ```truffle exec scripts/1_deploy_configurator.js --network ropsten```
3. After deployment, run the following command with one or more contracts that you wish to verify:  
    ```truffle run verify SomeContractName@SomeContractAddress AnotherContractName@AnotherContractAddress --network NetworkName [--debug]```  
    for example:  
    ```truffle run verify  Pride@0xd4eE90e82FE10d37d028084f262fbC092E2aEF81 --network ropsten```  
    You can find all information about deployed smart contracts in the file `report.NetworkName.log`.
#### How to get constructor arguements generated during deployment
1. Browse to your contract on Etherscan and click on the hash of the transaction with which it was created.
2. On the top right, where it reads "Tools & utilities", click on the arrow to see more options and select "Parity Trace".
3. For the action pertaining the contract creation, click on "Click to see more" below to see the input/output.
4. Copy the content of the "Init" field and paste somewhere in text file.
5. Copy "bytecode" string from ContractName.json generated by truffle and place it near the string from the previous step.
6. The difference between theese two strings is your encoded constructor arguements.
7. Pass them to `truffle-verify-plugin` as paramter: `--forceConstructorArgs string:ABIEncodedArguments`

### Wallets with BEP20 support
1. [MyEtherWallet](https://www.myetherwallet.com)
2. Parity
3. Mist/Ethereum wallet

EXODUS does not support BEP20, but provides the ability to export the private key to MyEtherWallet - http://support.exodus.io/article/128-how-do-i-receive-unsupported-erc20-tokens

## Main network configuration
### Contracts
* [Token](https://bscscan.com/address/0x085d15db9c7cd3df188422f88ec41ec573d691b9)
* [Vesting Wallet](https://bscscan.com/address/0xA8d3eEF1ca4f3eFB7289B19E31885a149B211Bd7)
* [Token Depositor](https://bscscan.com/address/0xF26e41b7ca8C8dAdc8798D75D85FBD853883234F)
* [Configurator](https://bscscan.com/address/0xB5037be25B0D4CC949f9BBFA2BaE62e3FcCca0DD)
* [StakingProgram](https://bscscan.com/address/0x723C896e82a6c4A617d4e1eace1Bb43070D8A2f3)

## Test network configuration (BSC Testnet)
### Contracts
* [Token](https://testnet.bscscan.com/token/0x0D8E7c62f192725d14559cC1DfDD884F9e8BA7Fb)
* [VestingWallet](https://testnet.bscscan.com/address/0xed3956e63bC7d848950BcC6B2B1c7957d5BBE7a4)
* [NFT](https://testnet.bscscan.com/token/0x363189488bcd7b928de7f954a131637fac0fe4b0)
* [NFTMinter](https://testnet.bscscan.com/address/0x2f1DE6Ea281cDA4FB277C12A4c88E5311CA1Fd3e)
* [NFTMarket](https://testnet.bscscan.com/address/0xf1584519eB9D58fe92e013f9cfbA9F38D42F92Ed)
* [NFTHolder](https://testnet.bscscan.com/address/0x0dD4215ddd66b0068682c13EFFa610a88b2Cf458)
* [PricingController](https://testnet.bscscan.com/address/0x54bF1D9518C98E59d28c30299948e321402e971C)
* [AccessController](https://testnet.bscscan.com/address/0xe9769F0b3327915eaF996e8425ef3dB41b9916c7)

You can find test log [here](docs/testnet.log.md)

## User's guide
You can find the user guide for end-users [here](docs/user.md)
