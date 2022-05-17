// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../lib/MarketItems.sol";


/**
 * @dev Interface of NFTMarket contract.
 */
interface INFTMarket {

    function addMarketItem(uint256 tokenId, uint256 price, MarketItems.Currency currency) external;

}
