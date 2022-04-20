// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


/**
 * @dev Interface of NFTMarket contract.
 */
interface INFTMarket {

    function addItemToMarket(uint256 tokenId, uint256 price) external;

}
