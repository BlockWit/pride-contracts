// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IPrideNFT.sol";
import "./RecoverableFunds.sol";
import "./interfaces/INFTMarket.sol";

contract NFTMinter is IERC721Receiver, Ownable, RecoverableFunds {

    IPrideNFT public token;
    INFTMarket public market;

    function setToken(address newTokenAddress) public onlyOwner {
        token = IPrideNFT(newTokenAddress);
    }

    function setMarket(address newMarketAddress) public onlyOwner {
        if (address(market) != address(0)) {
            token.setApprovalForAll(address(market), false);
        }
        market = INFTMarket(newMarketAddress);
        token.setApprovalForAll(newMarketAddress, true);
    }

    function mintAndAddToMarket(uint256[] calldata prices) external onlyOwner {
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 tokenId = token.safeMint(address(this));
            market.addItemToMarket(tokenId, prices[i]);
        }
    }

    function setApproval(address operator, bool approved) external onlyOwner {
        token.setApprovalForAll(operator, approved);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
