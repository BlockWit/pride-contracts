// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


interface IAccessController {

    function hasAccess(address account) external view returns (bool);

}
