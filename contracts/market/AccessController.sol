// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IAccessController.sol";
import "../RecoverableFunds.sol";
import "./AccessLevels.sol";

contract AccessController is IAccessController, RecoverableFunds, AccessControl {

    using AccessLevels for AccessLevels.Map;

    mapping(address => uint8) public accountLevels;
    AccessLevels.Map private accessLevels;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getAccessLevel(uint256 key) external view returns (AccessLevels.AccessLevel memory){
        return accessLevels.get(key);
    }

    function getAccessLevelKeys() external view returns (uint256[] memory keys){
        return accessLevels.keys();
    }

    function getAccessTime(address account) override external view returns (uint256) {
        if (account == address(0)) return accessLevels.get(0).start;
        uint256 timestamp;
        for (uint8 i = 0; i <= accountLevels[account]; i++) {
            timestamp = accessLevels.get(i).start;
        }
        return timestamp;
    }

    function setAccessLevel(uint256 key, uint256 start, uint256 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (accessLevels.contains(key)) {
            AccessLevels.AccessLevel storage level = accessLevels.get(key);
            level.start = start;
            level.end = start;
        } else {
            accessLevels.set(key, AccessLevels.AccessLevel(start, end));
        }
    }

    function removeAccessLevel(uint256 key) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return accessLevels.remove(key);
    }

    function setAccountLevels(address[] calldata accounts, uint8[] calldata levels) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(accounts.length == levels.length, "Whitelist: Incorrect array length.");
        for (uint256 i = 0; i < accounts.length; i++) {
            accountLevels[accounts[i]] = levels[i];
        }
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
