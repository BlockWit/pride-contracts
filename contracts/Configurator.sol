// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVestingWallet.sol";
import "./RecoverableFunds.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ITokenDepositor.sol";
import "./VestingWallet.sol";
import "./TokenDepositor.sol";
import "./lib/Stages.sol";

contract Configurator is RecoverableFunds {

    struct Amounts {
        uint256 team;
        uint256 advisors;
        uint256 ingame;
        uint256 marketmaking;
    }

    struct Addresses {
        address owner;
        address team;
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
        schedules[0].start =      1648814400;         // April 1 2022 12:00:00 UTC
        schedules[0].duration =   0;
        schedules[0].interval =   0;
        // Private Sale Pool 1
        schedules[1].start =      1659182400;         // April 1 2022 12:00:00 UTC + 30 days delay
        schedules[1].duration =   360 days;
        schedules[1].interval =   1 days;
        // Private Sale Pool 2
        schedules[2].start =      1659182400;         // April 1 2022 12:00:00 UTC + 30 days delay
        schedules[2].duration =   360 days;
        schedules[2].interval =   1 days;
        // Private Sale Pool 3
        schedules[3].start =      1659182400;         // April 1 2022 12:00:00 UTC + 30 days delay
        schedules[3].duration =   360 days;
        schedules[3].interval =   1 days;
        // Public Sale
        schedules[4].start =      1648814400;         // April 1 2022 12:00:00 UTC
        schedules[4].duration =   300 days;
        schedules[4].interval =   30 days;
        // Team
        schedules[5].start =      1679918400;         // April 1 2022 12:00:00 UTC + 360 days delay
        schedules[5].duration =   300 days;
        schedules[5].interval =   30 days;
        // Advisors & Influencers
        schedules[6].start =      1659182400;         // April 1 2022 12:00:00 UTC + 120 days delay
        schedules[6].duration =   360 days;
        schedules[6].interval =   30 days;
        // Ingame mechanics
        schedules[7].start =      1664366400;         // April 1 2022 12:00:00 UTC + 180 days delay
        schedules[7].duration =   1500 days;
        schedules[7].interval =   30 days;
        // Market-making
        schedules[8].start =      1641038400;         // April 1 2022 12:00:00 UTC - 90 days delay
        schedules[8].duration =   360 days;
        schedules[8].interval =   90 days;

        Amounts memory amounts;

        amounts.team =            35_000_000 ether;
        amounts.advisors =         2_500_000 ether;
        amounts.ingame =         150_000_000 ether;
        amounts.marketmaking =     2_500_000 ether;

        Addresses memory addresses;

        addresses.owner =           address(0xAdF3bFAcf63b401163FFbf1040B97C6d024c3c9A);
        addresses.team =            address(0xe528bD9B1c6F8DAFCf93A93b51f6d3457840aA7c);
        addresses.advisors =        address(0x0296e6cB65e895144aEEACA59450C2F599B04b11);
        addresses.ingame =          address(0x19b40778fa9cb52f143a0ABeBef32F93E861075B);
        addresses.marketmaking =    address(0xC828729fc22bd4D42750062Dd0ecF8D8DA87Ab5D);

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
        token.transfer(_depositor, amounts.team + amounts.advisors + amounts.ingame + amounts.marketmaking);
        depositor.deposit(0,  5, addresses.team,            amounts.team);
        depositor.deposit(0,  6, addresses.advisors,        amounts.advisors);
        depositor.deposit(0,  7, addresses.ingame,          amounts.ingame);
        depositor.deposit(0,  8, addresses.marketmaking,    amounts.marketmaking);

        token.transfer(addresses.owner, token.balanceOf(address(this)));

        // transfer ownership
        IOwnable(_token).transferOwnership(addresses.owner);
        IOwnable(_depositor).transferOwnership(addresses.owner);
        IOwnable(_wallet).transferOwnership(addresses.owner);
    }

}
