// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../interfaces/INFTMarket.sol";


interface IPricingController {

    function calculatePrice(INFTMarket.MarketItem calldata item) external view returns (uint256);

}
