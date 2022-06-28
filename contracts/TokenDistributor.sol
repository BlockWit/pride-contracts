// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RecoverableFunds.sol";


contract TokenDistributor is Ownable, RecoverableFunds {

    IERC20 public token;

    function setToken(address newTokenAddress) public onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function distribute(address[] memory receivers, uint[] memory balances) public onlyOwner {
        for(uint i = 0; i < receivers.length; i++) {
            token.transfer(receivers[i], balances[i]);
        }
    }

}
