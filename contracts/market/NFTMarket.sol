// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interfaces/IAccessController.sol";
import "../interfaces/INFTMarket.sol";
import "../interfaces/IPricingController.sol";


contract NFTMarket is INFTMarket, Pausable, AccessControl {

    event MarketItemUpdated (uint256 indexed tokenId);
    event MarketItemsUpdated (uint256[] tokenIds);
    event MarketItemSold (uint256 indexed tokenId, uint256 price, Currency currency, address buyer, uint256 timestamp);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(uint256 => MarketItem) public items;
    mapping(address => Purchase[]) public history;
    IERC721Enumerable public prideNFT;
    IERC20 public prideToken;
    IERC20 public erc20;
    address public manager;
    address public holder;
    IPricingController public pricingController;
    IAccessController public accessController;
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

    function setPrideNFT(address newNFTAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        prideNFT = IERC721Enumerable(newNFTAddress);
    }

    function setPrideToken(address newPrideAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        prideToken = IERC20(newPrideAddress);
    }

    function setERC20(address newERC20Address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20 = IERC20(newERC20Address);
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

    function setAccessController(address newAccessControllerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        accessController = IAccessController(newAccessControllerAddress);
    }

    function setPricingController(address newPricingControllerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        pricingController = IPricingController(newPricingControllerAddress);
    }

    function getAccessTime(address account) external view returns (uint256) {
        return accessController.getAccessTime(account);
    }

    function getMarketItem(uint256 tokenId) external view returns (MarketItem memory) {
        return items[tokenId];
    }

    function getMarketItems() external view returns (MarketItem[] memory marketItems) {
        uint256 amount = prideNFT.balanceOf(holder);
        for (uint256 i; i < amount; i++) {
            uint256 id = prideNFT.tokenOfOwnerByIndex(holder, i);
            marketItems[i] = items[id];
        }
        return marketItems;
    }

    function getMarketItemsWithPrices(uint256[] calldata tokenIds) external view returns (MarketItemWithPrices[] memory marketItems) {
        for (uint256 i; i < tokenIds.length; i++) {
            MarketItem memory item = items[tokenIds[i]];
            IPricingController.PriceStep[] memory prices = pricingController.calculatePriceLadder(item);
            marketItems[i] = MarketItemWithPrices(tokenIds[i], item.currency, prices);
        }
        return marketItems;
    }

    function getMarketItemsLength() external view returns (uint256) {
        return prideNFT.balanceOf(holder);
    }

    function getPurchaseHistory(address account) external view returns (Purchase[] memory) {
        return history[account];
    }

    function _setMarketItem(uint256 tokenId, uint256 price, uint256 pricingStrategy, Currency currency) internal {
        items[tokenId] = MarketItem(price, pricingStrategy, currency);
    }

    function setMarketItem(uint256 tokenId, uint256 price, uint256 pricingStrategy, Currency currency) override external onlyRole(MANAGER_ROLE) {
        _setMarketItem(tokenId, price, pricingStrategy, currency);
        emit MarketItemUpdated(tokenId);
    }

    function setMarketItems(uint256[] calldata tokenIds, uint256[] calldata prices, uint256[] calldata pricingStrategies, Currency[] calldata currencies) override external onlyRole(MANAGER_ROLE) {
        require(tokenIds.length == prices.length && prices.length == pricingStrategies.length && pricingStrategies.length == currencies.length, "NFTMarket: wrong array length");
        for (uint256 i; i < tokenIds.length; i++) {
            _setMarketItem(tokenIds[i], prices[i], pricingStrategies[i], currencies[i]);
        }
        emit MarketItemsUpdated(tokenIds);
    }

    function retrieveERC20(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

    function buy(uint256[] calldata tokenIds) external payable whenNotPaused {
        require(accessController.hasAccess(msg.sender), "NFTMarket: You do not have access to the sale at the moment");
        uint256 totalAmountPRIDE;
        uint256 totalAmountERC20;
        uint256 totalAmountNative;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            MarketItem memory item = items[tokenIds[i]];
            uint256 price = pricingController.calculatePrice(item);
            if (item.currency == Currency.PRIDE) {
                totalAmountPRIDE += price;
            } else if (item.currency == Currency.ERC20) {
                totalAmountERC20 += price;
            } else if (item.currency == Currency.NATIVE) {
                totalAmountNative += price;
            } else {
                revert("NFTMakret: This item is not available for sale in the specified currency");
            }
            prideNFT.transferFrom(holder, msg.sender, tokenIds[i]);
            history[msg.sender].push(Purchase(tokenIds[i], price, item.currency, block.timestamp));
            emit MarketItemSold(tokenIds[i], item.price, item.currency, msg.sender, block.timestamp);
        }
        if (totalAmountPRIDE > 0) {
            prideToken.transferFrom(msg.sender, fundraisingWallet, totalAmountPRIDE);
        }
        if (totalAmountERC20 > 0) {
            erc20.transferFrom(msg.sender, fundraisingWallet, totalAmountERC20);
        }
        uint256 change = msg.value;
        if (totalAmountNative > 0) {
            require(msg.value >= totalAmountNative, "NFTMarket: Not enough funds");
            fundraisingWallet.transfer(totalAmountNative);
            change -= totalAmountNative;
        }
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

}
