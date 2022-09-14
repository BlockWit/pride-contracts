// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPrideNFT.sol";


contract SimpleNFTMinter is AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public token;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setToken(address newTokenAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        token = newTokenAddress;
    }

    function mint(uint256 amount, address recipient) external onlyRole(MINTER_ROLE) {
        IPrideNFT _token = IPrideNFT(token);
        for (uint256 i = 0; i < amount; i++) {
            _token.safeMint(recipient);
        }
    }

    function retrieveERC20(address recipient, address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipient.transfer(address(this).balance);
    }

}
