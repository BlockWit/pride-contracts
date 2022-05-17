// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/IPrideNFT.sol";

contract NFTHolder is ERC721Holder, AccessControl {

    IPrideNFT public token;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setToken(address newTokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IPrideNFT(newTokenAddress);
    }

    function setApproval(address operator, bool approved) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.setApprovalForAll(operator, approved);
    }

    function retrieveERC20(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

}
