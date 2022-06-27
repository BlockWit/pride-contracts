// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "../interfaces/IPricingController.sol";
import "../RecoverableFunds.sol";
import "./PricingStrategies.sol";

contract PricingController is IPricingController,  RecoverableFunds {

    using PricingStrategies for PricingStrategies.Map;

    PricingStrategies.Map private pricingStrategies;

    function calculatePrice(INFTMarket.MarketItem calldata item) override external view returns (uint256 sum) {
        PricingStrategies.PricingStrategy storage strategy = pricingStrategies.get(item.pricingStrategy);
        uint256 time = strategy.start;
        for (uint256 i = 0; i < strategy.intervals.length; i++) {
            time += strategy.intervals[i];
            if (block.timestamp < time) {
                sum += strategy.priceStep;
            } else {
                break;
            }
        }
        return item.price + sum;
    }

}
