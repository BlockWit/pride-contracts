// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPrideNFT.sol";
import "./lib/MarketItems.sol";

contract NFTMarket is Pausable, AccessControl {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    using MarketItems for MarketItems.Map;

    IPrideNFT public token;
    MarketItems.Map private items;
    address public manager;
    address public holder;
    address payable public fundraisingWallet;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setFundraisingWallet(address payable newFundraisingWalletAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fundraisingWallet = newFundraisingWalletAddress;
    }

    function setManager(address newManagerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (hasRole(MANAGER_ROLE, manager)) {
            _revokeRole(MANAGER_ROLE, manager);
        }
        manager = newManagerAddress;
        _grantRole(MANAGER_ROLE, newManagerAddress);
    }

    function setToken(address newTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IPrideNFT(newTokenAddress);
    }

    function setHolder(address newHolderAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        holder = newHolderAddress;
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

    function addMarketItem(uint256 tokenId, uint256 price) external onlyRole(MANAGER_ROLE) {
        require(!items.contains(tokenId), "NFTMarket: This item is already on sale");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price));
    }

    function updateMarketItem(uint256 tokenId, uint256 price) external onlyRole(MANAGER_ROLE) {
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price));
    }

    function removeMarketItem(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.remove(tokenId);
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

    function buy(uint256 tokenId) external payable whenNotPaused {
        MarketItems.MarketItem memory item = items.get(tokenId);
        require(msg.value >= item.price, "NFTMarket: Not enough funds");
        fundraisingWallet.transfer(item.price);
        items.remove(tokenId);
        token.transferFrom(holder, msg.sender, tokenId);
        uint256 change = msg.value - item.price;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

}
