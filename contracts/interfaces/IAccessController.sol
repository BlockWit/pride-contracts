// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


interface IAccessController {

    function getAccessTime(address account) external view returns (uint256);

    function hasAccess(address account) external view returns (bool);

}
