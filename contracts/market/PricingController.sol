// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPricingController.sol";
import "../RecoverableFunds.sol";
import "./PricingStrategies.sol";

contract PricingController is IPricingController, RecoverableFunds, AccessControl {

    using PricingStrategies for PricingStrategies.Map;

    PricingStrategies.Map private pricingStrategies;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getPricingStrategy(uint256 key) external view returns (PricingStrategies.PricingStrategy memory){
        return pricingStrategies.get(key);
    }

    function getPricingStrategyKeys() external view returns (uint256[] memory keys){
        return pricingStrategies.keys();
    }

    function setPricingStrategy(uint256 key, uint256 start, uint256[] calldata intervals, uint256 priceStep) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (pricingStrategies.contains(key)) {
            PricingStrategies.PricingStrategy storage strategy = pricingStrategies.get(key);
            strategy.start = start;
            strategy.intervals = intervals;
            strategy.priceStep = priceStep;
        } else {
            pricingStrategies.set(key, PricingStrategies.PricingStrategy(start, intervals, priceStep));
        }
    }

    function removePricingStrategy(uint256 key) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return pricingStrategies.remove(key);
    }

    function calculatePrice(INFTMarket.MarketItem calldata item) override external view returns (uint256 sum) {
        PricingStrategies.PricingStrategy storage strategy = pricingStrategies.get(item.pricingStrategy);
        uint256 time = strategy.start;
        for (uint256 i = 0; i < strategy.intervals.length; i++) {
            time += strategy.intervals[i];
            if (block.timestamp > time) {
                sum += strategy.priceStep;
            } else {
                break;
            }
        }
        return item.price + sum;
    }

}
