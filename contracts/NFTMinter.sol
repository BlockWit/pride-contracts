// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPrideNFT.sol";
import "./interfaces/INFTMarket.sol";
import "./lib/MarketItems.sol";

contract NFTMinter is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public market;
    address public token;
    address public holder;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setToken(address newTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = newTokenAddress;
    }

    function setMarket(address newMarketAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        market = newMarketAddress;
    }

    function setHolder(address newHolderAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        holder = newHolderAddress;
    }

    function mintAndAddToMarket(uint256[] calldata prices, MarketItems.Currency[] calldata currencies) external onlyRole(MINTER_ROLE) {
        IPrideNFT _token = IPrideNFT(token);
        INFTMarket _market = INFTMarket(market);
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 tokenId = _token.safeMint(holder);
            _market.addMarketItem(tokenId, prices[i], currencies[i]);
        }
    }

    function retrieveERC20(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

}
