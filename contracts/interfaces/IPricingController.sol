// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../interfaces/INFTMarket.sol";


interface IPricingController {

    struct PriceStep {
        uint256 timestamp;
        uint256 price;
    }

    function calculatePrice(INFTMarket.MarketItem calldata item) external view returns (uint256);

    function calculatePriceLadder(INFTMarket.MarketItem calldata item) external view returns (PriceStep[] memory);

}
