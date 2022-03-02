// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RecoverableFunds.sol";
import "./lib/Schedules.sol";
import "./interfaces/IVestingWallet.sol";

contract VestingWallet is IVestingWallet, Ownable, RecoverableFunds {

    using SafeMath for uint256;
    using Schedules for Schedules.Map;

    struct Balance {
        uint256 initial;
        uint256 withdrawn;
    }

    IERC20 public token;
    Schedules.Map private schedules;
    mapping(uint256 => mapping(address => Balance)) public balances;

    event Deposit(uint256 schedule, address account, uint256 tokens);
    event Withdrawal(address account, uint256 tokens);

    function setToken(address tokenAddress) override public onlyOwner {
        token = IERC20(tokenAddress);
    }

    function setVestingSchedule(uint256 id, uint256 start, uint256 duration, uint256 interval) override public onlyOwner returns (bool) {
        return schedules.set(id, Schedules.Schedule(start, duration, interval));
    }

    function removeVestingSchedule(uint256 id) override public onlyOwner returns (bool) {
        return schedules.remove(id);
    }

    function getVestingSchedule(uint256 id) override public view returns (Schedules.Schedule memory) {
        return schedules.get(id);
    }

    function setBalance(uint256 schedule, address account, uint256 initial, uint256 withdrawn) override public onlyOwner {
        balances[schedule][account] = Balance(initial, withdrawn);
    }

    function deposit(uint256 schedule, address[] calldata beneficiaries, uint256[] calldata amounts) override public {
        require(beneficiaries.length == amounts.length, "VestingWallet: Incorrect array length.");
        uint256 sum;
        for (uint256 i = 0; i < amounts.length; i++) {
            sum = sum.add(amounts[i]);
        }
        token.transferFrom(msg.sender, address(this), sum);
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            _deposit(schedule, beneficiaries[i], amounts[i]);
        }
    }

    function deposit(uint256 schedule, address beneficiary, uint256 amount) public override {
        token.transferFrom(msg.sender, address(this), amount);
        _deposit(schedule, beneficiary, amount);
    }

    function _deposit(uint256 schedule, address beneficiary, uint256 amount) internal {
        Balance storage balance = balances[schedule][beneficiary];
        balance.initial = balance.initial.add(amount);
        emit Deposit(schedule, beneficiary, amount);
    }

    function getAccountInfo(address account) override public view returns (uint256, uint256, uint256) {
        uint256 initial;
        uint256 withdrawn;
        uint256 vested;
        for (uint256 index = 0; index < schedules.length(); index++) {
            Balance memory balance = balances[index][account];
            Schedules.Schedule memory schedule = schedules.get(index);
            uint256 vestedAmount = _calculateVestedAmount(balance, schedule);
            initial = initial.add(balance.initial);
            withdrawn = withdrawn.add(balance.withdrawn);
            vested = vested.add(vestedAmount);
        }
        return (initial, withdrawn, vested);
    }

    function withdraw() override public returns (uint256) {
        uint256 tokens;
        for (uint256 index = 0; index < schedules.length(); index++) {
            Balance storage balance = balances[index][msg.sender];
            if (balance.initial == 0) continue;
            Schedules.Schedule memory schedule = schedules.get(index);
            uint256 vestedAmount = _calculateVestedAmount(balance, schedule);
            if (vestedAmount == 0) continue;
            balance.withdrawn = balance.withdrawn.add(vestedAmount);
            tokens = tokens.add(vestedAmount);
        }
        require(tokens > 0, "VestingWallet: No tokens available for withdrawal");
        token.transfer(msg.sender, tokens);
        emit Withdrawal(msg.sender, tokens);
        return tokens;
    }

    function _calculateVestedAmount(Balance memory balance, Schedules.Schedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.start) return 0;
        uint256 tokensAvailable;
        if (block.timestamp >= schedule.start.add(schedule.duration)) {
            tokensAvailable = balance.initial;
        } else {
            uint256 parts = schedule.duration.div(schedule.interval);
            uint256 tokensByPart = balance.initial.div(parts);
            uint256 timeSinceStart = block.timestamp.sub(schedule.start);
            uint256 pastParts = timeSinceStart.div(schedule.interval);
            tokensAvailable = tokensByPart.mul(pastParts);
        }
        return tokensAvailable.sub(balance.withdrawn);
    }

}
