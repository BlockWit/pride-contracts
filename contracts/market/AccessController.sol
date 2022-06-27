// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IAccessController.sol";
import "../RecoverableFunds.sol";
import "./AccessLevels.sol";

contract AccessController is IAccessController, RecoverableFunds {

    using AccessLevels for AccessLevels.Map;

    mapping(address => uint8) private accountLevels;
    AccessLevels.Map private accessLevels;

    function setAccountLevel(address[] calldata accounts, uint8[] calldata levels) external {
        require(accounts.length == levels.length, "Whitelist: Incorrect array length.");
        for (uint256 i = 0; i < accounts.length; i++) {
            accountLevels[accounts[i]] = levels[i];
        }
    }

    function getAccountLevel(address account) external view returns (uint8) {
        return accountLevels[account];
    }

    function hasAccess(address account) override external view returns (bool) {
        uint8 accountLevel = accountLevels[account];
        for (uint256 i = 0; i <= accountLevel; i++) {
            AccessLevels.AccessLevel storage accessLevel = accessLevels.get(i);
            if (block.timestamp >= accessLevel.start && block.timestamp < accessLevel.end) {
                return true;
            }
        }
        return false;
    }

}
