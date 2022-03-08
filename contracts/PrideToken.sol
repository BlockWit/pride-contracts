// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./RecoverableFunds.sol";

contract PrideToken is ERC20Burnable, RecoverableFunds {
    constructor() payable ERC20("PRIDE Token", "PRIDE") {
        _mint(_msgSender(), 250_000_000 ether);
    }
}
