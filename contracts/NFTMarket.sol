// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IPrideNFT.sol";
import "./RecoverableFunds.sol";
import "./lib/MarketItems.sol";

contract NFTMarket is Pausable, RecoverableFunds {

    using MarketItems for MarketItems.Map;

    IPrideNFT public token;
    MarketItems.Map private items;
    address public minter;
    address payable public fundraisingWallet;

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setFundraisingWallet(address payable newFundraisingWalletAddress) external onlyOwner {
        fundraisingWallet = newFundraisingWalletAddress;
    }

    function setMinterAddress(address newMinterAddress) external onlyOwner {
        minter = newMinterAddress;
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        token = IPrideNFT(newTokenAddress);
    }

    function getMarketItemByTokenId(uint256 tokenId) external view returns (MarketItems.MarketItem memory) {
        return items.get(tokenId);
    }

    function getMarketItemAt(uint256 position) external view returns (uint256, MarketItems.MarketItem memory) {
        return items.at(position);
    }

    function getMarketItemsLength() external view returns (uint256) {
        return items.length();
    }

    function addItemToMarket(uint256 tokenId, uint256 price) external {
        require(minter == _msgSender() || owner() == _msgSender(), "NFTMarket: Only owner or minter can use this method");
        require(!items.contains(tokenId), "NFTMarket: This item is already on sale");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price));
    }

    function updateMarketItem(uint256 tokenId, uint256 price) external {
        require(minter == _msgSender() || owner() == _msgSender(), "NFTMarket: Only owner or minter can use this method");
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price));
    }

    function removeMarketItem(uint256 tokenId) external {
        require(minter == _msgSender() || owner() == _msgSender(), "NFTMarket: Only owner or minter can use this method");
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.remove(tokenId);
    }

    function buy(uint256 tokenId) external payable whenNotPaused {
        MarketItems.MarketItem memory item = items.get(tokenId);
        require(msg.value >= item.price, "NFTMarket: Not enough funds");
        fundraisingWallet.transfer(item.price);
        items.remove(tokenId);
        token.transferFrom(minter, msg.sender, tokenId);
        uint256 change = msg.value - item.price;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

}
