// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../lib/Schedules.sol";

/**
 * @dev Interface of VestingWallet contract.
 */
interface IVestingWallet {

    function setToken(address tokenAddress) external;
    function setVestingSchedule(uint256 id, uint256 start, uint256 duration, uint256 interval) external returns (bool);
    function removeVestingSchedule(uint256 id) external returns (bool);
    function getVestingSchedule(uint256 id) external returns (Schedules.Schedule memory);
    function setBalance(uint256 schedule, address account, uint256 initial, uint256 withdrawn) external;
    function deposit(uint256 schedule, address beneficiary, uint256 amount) external;
    function deposit(uint256 schedule, address[] calldata beneficiaries, uint256[] calldata amounts) external;
    function getAccountInfo(address account) external view returns (uint256, uint256, uint256);
    function withdraw() external returns (uint256);

}
