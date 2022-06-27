// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVestingWallet.sol";
import "./RecoverableFunds.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ITokenDepositor.sol";
import "./VestingWallet.sol";
import "./TokenDepositor.sol";

contract Configurator is RecoverableFunds {

    struct Amounts {
        uint256 team1;
        uint256 team2;
        uint256 team3;
        uint256 team4;
        uint256 advisors;
        uint256 ingame;
        uint256 marketmaking;
    }

    struct Addresses {
        address owner;
        address team1;
        address team2;
        address team3;
        address team4;
        address advisors;
        address ingame;
        address marketmaking;
    }

    IERC20 public token;
    IVestingWallet public wallet;
    ITokenDepositor public depositor;

    function init(address _token, address _wallet, address _depositor) public onlyOwner {

        Schedules.Schedule[9] memory schedules;

        // Unlocked on start
        schedules[0].start =      1647950400;         // March 22 2022 12:00:00 UTC
        schedules[0].duration =   0;
        schedules[0].interval =   0;
        // Private Sale Pool 1
        schedules[1].start =      1658318400;         // March 22 2022 12:00:00 UTC + 120 days delay
        schedules[1].duration =   360 days;
        schedules[1].interval =   1 days;
        // Private Sale Pool 2
        schedules[2].start =      1658318400;         // March 22 2022 12:00:00 UTC + 120 days delay
        schedules[2].duration =   360 days;
        schedules[2].interval =   1 days;
        // Private Sale Pool 3
        schedules[3].start =      1658318400;         // March 22 2022 12:00:00 UTC + 120 days delay
        schedules[3].duration =   360 days;
        schedules[3].interval =   1 days;
        // Public Sale
        schedules[4].start =      1647950400;         // March 22 2022 12:00:00 UTC
        schedules[4].duration =   300 days;
        schedules[4].interval =   30 days;
        // Team
        schedules[5].start =      1676462400;         // March 22 2022 12:00:00 UTC + 330 days delay
        schedules[5].duration =   300 days;
        schedules[5].interval =   30 days;
        // Advisors & Influencers
        schedules[6].start =      1658318400;         // March 22 2022 12:00:00 UTC + 120 days delay
        schedules[6].duration =   360 days;
        schedules[6].interval =   30 days;
        // Ingame mechanics
        schedules[7].start =      1663502400;         // March 22 2022 12:00:00 UTC + 180 days delay
        schedules[7].duration =   1500 days;
        schedules[7].interval =   30 days;
        // Market-making
        schedules[8].start =      1640174400;         // March 22 2022 12:00:00 UTC - 90 days delay
        schedules[8].duration =   360 days;
        schedules[8].interval =   90 days;

        Amounts memory amounts;

        amounts.team1 =            5_000_000 ether;
        amounts.team2 =           10_000_000 ether;
        amounts.team3 =           10_000_000 ether;
        amounts.team4 =           10_000_000 ether;
        amounts.advisors =         2_500_000 ether;
        amounts.ingame =         150_000_000 ether;
        amounts.marketmaking =     2_500_000 ether;

        Addresses memory addresses;

        addresses.owner =           address(0xaAFaC0Cc1Ca2100974899de1c21B35b0254a0e21);
        addresses.team1 =           address(0x03cf5F0C29a80A0e363d6f87Aa75DD71CEE04d69);
        addresses.team2 =           address(0x264cbBAe29956d9af0338992f297bcC8028256C3);
        addresses.team3 =           address(0x185611195F85E0eCb33657eB499ef8c0D01D3CeF);
        addresses.team4 =           address(0x402F0a8e4632472856F77C0A73CB0048D3609A9D);
        addresses.advisors =        address(0x3cF0c3961C2b6bC1EB2FEEb7541BD0643Ba31Fd4);
        addresses.ingame =          address(0x162Af96d550DbBf8fd88c73940DD2c007614A03C);
        addresses.marketmaking =    address(0x0198F65235C0Cd99Def7EF0d3e2995E3e2040986);

        token = IERC20(_token);
        wallet = IVestingWallet(_wallet);
        depositor = ITokenDepositor(_depositor);

        token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));

        // configure VestingWallet
        wallet.setToken(_token);
        for (uint256 i; i < schedules.length; i++) {
            wallet.setVestingSchedule(i, schedules[i].start,   schedules[i].duration,  schedules[i].interval);
        }

        // configure TokenDepositor
        depositor.setToken(_token);
        depositor.setVestingWallet(_wallet);
        token.transfer(_depositor, amounts.team1 + amounts.team2 + amounts.team3 + amounts.team4 + amounts.advisors + amounts.ingame + amounts.marketmaking);
        depositor.deposit(0,  5, addresses.team1,           amounts.team1);
        depositor.deposit(0,  5, addresses.team2,           amounts.team2);
        depositor.deposit(0,  5, addresses.team3,           amounts.team3);
        depositor.deposit(0,  5, addresses.team4,           amounts.team4);
        depositor.deposit(0,  6, addresses.advisors,        amounts.advisors);
        depositor.deposit(0,  7, addresses.ingame,          amounts.ingame);
        depositor.deposit(0,  8, addresses.marketmaking,    amounts.marketmaking);

        token.transfer(addresses.owner, token.balanceOf(address(this)));

        // transfer ownership
        IOwnable(_token).transferOwnership(addresses.owner);
        IOwnable(_depositor).transferOwnership(msg.sender);
        IOwnable(_wallet).transferOwnership(msg.sender);
    }

}
