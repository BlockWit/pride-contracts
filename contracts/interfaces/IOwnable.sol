// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev Interface of Ownable contract.
 */
interface IOwnable {

    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;

}
