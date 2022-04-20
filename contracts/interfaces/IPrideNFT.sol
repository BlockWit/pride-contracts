// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev Interface of PrideNFT contract.
 */
interface IPrideNFT is IERC721Enumerable {

    function safeMint(address to) external returns (uint256);

}
