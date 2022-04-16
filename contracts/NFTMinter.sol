// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IPrideNFT.sol";
import "./RecoverableFunds.sol";

contract NFTMinter is Ownable, RecoverableFunds {

    IPrideNFT public token;

    function setToken(address newTokenAddress) public onlyOwner {
        token = IPrideNFT(newTokenAddress);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            token.safeMint(to);
        }
    }
}
