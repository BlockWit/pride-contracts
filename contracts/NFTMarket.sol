// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./lib/MarketItems.sol";

contract NFTMarket is Pausable, AccessControl {

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    using MarketItems for MarketItems.Map;

    MarketItems.Map private items;
    address public nft;
    address public pride;
    address public erc20;
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

    function setNFT(address newNFTAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft = newNFTAddress;
    }

    function setPride(address newPrideAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pride = newPrideAddress;
    }

    function setERC20(address newERC20Address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20 = newERC20Address;
    }

    function setManager(address newManagerAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (hasRole(MANAGER_ROLE, manager)) {
            _revokeRole(MANAGER_ROLE, manager);
        }
        manager = newManagerAddress;
        _grantRole(MANAGER_ROLE, newManagerAddress);
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

    function getMarketItemIds() external view returns (uint256[] memory) {
        return items.keys();
    }

    function getMarketItemsLength() external view returns (uint256) {
        return items.length();
    }

    function addMarketItem(uint256 tokenId, uint256 price, MarketItems.Currency currency) external onlyRole(MANAGER_ROLE) {
        require(!items.contains(tokenId), "NFTMarket: This item is already on sale");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price, currency));
    }

    function updateMarketItem(uint256 tokenId, uint256 price, MarketItems.Currency currency) external onlyRole(MANAGER_ROLE) {
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.set(tokenId, MarketItems.MarketItem(tokenId, price, currency));
    }

    function removeMarketItem(uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        require(items.contains(tokenId), "NFTMarket: Item not found");
        items.remove(tokenId);
    }

    function retrieveERC20(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

    function buy(uint256[] calldata tokenIds) external payable whenNotPaused {
        uint256 totalAmount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            MarketItems.MarketItem memory item = items.get(tokenIds[i]);
            require(item.currency == MarketItems.Currency.NATIVE, "NFTMakret: Item is not available for sale in native currency");
            totalAmount += item.price;
            items.remove(item.tokenId);
            IERC721(nft).transferFrom(holder, msg.sender, item.tokenId);
        }
        require(msg.value >= totalAmount, "NFTMarket: Not enough funds");
        fundraisingWallet.transfer(totalAmount);
        uint256 change = msg.value - totalAmount;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

    function buyForERC20(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 totalAmountPRIDE;
        uint256 totalAmountERC20;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            MarketItems.MarketItem memory item = items.get(tokenIds[i]);
            if (item.currency == MarketItems.Currency.PRIDE) {
                totalAmountPRIDE += item.price;
            } else if (item.currency == MarketItems.Currency.ERC20) {
                totalAmountERC20 += item.price;
            } else {
                revert("NFTMakret: This item is not available for sale in the specified currency");
            }
            items.remove(item.tokenId);
            IERC721(nft).transferFrom(holder, msg.sender, item.tokenId);
        }
        if (totalAmountPRIDE > 0) {
            IERC20(pride).transferFrom(msg.sender, fundraisingWallet, totalAmountPRIDE);
        }
        if (totalAmountERC20 > 0) {
            IERC20(erc20).transferFrom(msg.sender, fundraisingWallet, totalAmountERC20);
        }
    }

}
