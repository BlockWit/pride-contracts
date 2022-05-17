// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IPrideNFT.sol";
import "./RecoverableFunds.sol";
import "./interfaces/INFTMarket.sol";

contract NFTMinter is IERC721Receiver, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IPrideNFT public token;
    INFTMarket public market;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setToken(address newTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IPrideNFT(newTokenAddress);
    }

    function setMarket(address newMarketAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(market) != address(0)) {
            token.setApprovalForAll(address(market), false);
        }
        market = INFTMarket(newMarketAddress);
        token.setApprovalForAll(newMarketAddress, true);
    }

    function mintAndAddToMarket(uint256[] calldata prices) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < prices.length; i++) {
            uint256 tokenId = token.safeMint(address(this));
            market.addItemToMarket(tokenId, prices[i]);
        }
    }

    function setApproval(address operator, bool approved) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.setApprovalForAll(operator, approved);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

}
