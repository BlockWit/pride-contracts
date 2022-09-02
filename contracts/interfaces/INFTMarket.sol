// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPricingController.sol";


/**
 * @dev Interface of NFTMarket contract.
 */
interface INFTMarket {

    enum Currency { PRIDE, ERC20, NATIVE }

    struct MarketItem {
        uint256 price;
        uint256 pricingStrategy;
        Currency currency;
    }

    struct MarketItemWithPrices {
        uint256 tokenId;
        Currency currency;
        IPricingController.PriceStep[] prices;
    }

    struct Purchase {
        uint256 tokenId;
        uint256 price;
        Currency currency;
        uint256 timestamp;
    }

    function setMarketItem(uint256 tokenId, uint256 price, uint256 pricingStrategy, Currency currency) external;

    function setMarketItems(uint256[] calldata tokenIds, uint256[] calldata prices, uint256[] calldata pricingStrategies, Currency[] calldata currencies) external;

}
