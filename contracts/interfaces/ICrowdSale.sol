// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../lib/Stages.sol";
import "./IOwnable.sol";

/**
 * @dev Interface of CrowdSale contract.
 */
interface ICrowdSale {

    function pause() external;
    function unpause() external;
    function setToken(address newTokenAddress) external;
    function setBUSD(address newTokenAddress) external;
    function setVestingWallet(address newVestingWalletAddress) external;
    function setPercentRate(uint256 newPercentRate) external;
    function setFundraisingWallet(address payable newFundraisingWalletAddress) external;
    function setPrice(uint256 newPrice) external;
    function setStage(uint256 id, uint256 start, uint256 end, uint256 bonus, uint256 minInvestmentLimit, uint256 hardcapInTokens, uint256 vestingSchedule, uint256 unlockedOnTGE, uint256 invested, uint256 tokensSold, bool whitelist) external returns (bool);
    function removeStage(uint256 id) external returns (bool);
    function getStage(uint256 id) external returns (Stages.Stage memory);
    function addToWhitelist(address[] calldata accounts) external;
    function removeFromWhitelist(address[] calldata accounts) external;
    function getActiveStageIndex() external returns (bool, uint256);

}
