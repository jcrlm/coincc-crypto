// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Coincc is ERC20, Ownable {
    uint256 public buyTax = 10; // 10% tax compra
    uint256 public sellTax = 10; // 10% tax venta
    uint256 public marketingPct = 60; // 60% del tax a marketing wallet (tú)
    uint256 public liquidityPct = 40; // 40% a LP

    address public marketingWallet;
    address public pair;

    // Anti-bot fair launch
    uint256 public maxTx = totalSupply() * 2 / 100; // 2% max por tx
    uint256 public maxWallet = totalSupply() * 3 / 100; // 3% max por wallet
    bool public antiBot = true;

    mapping(address => bool) public excludedFromFees;

    constructor(address _marketing) ERC20("Coincc", "COINCC") {
        marketingWallet = _marketing;
        _mint(msg.sender, 1_000_000_000 * 10**decimals()); // 1 billón tokens

        excludedFromFees[msg.sender] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (excludedFromFees[from] || excludedFromFees[to]) {
            super._transfer(from, to, amount);
            return;
        }

        if (antiBot) {
            require(amount <= maxTx, "Max tx exceeded");
            require(balanceOf(to) + amount <= maxWallet, "Max wallet exceeded");
        }

        uint256 fees = 0;
        if (to == pair || from == pair) {
            uint256 tax = (from == pair) ? buyTax : sellTax;
            fees = amount * tax / 100;

            uint256 marketing = fees * marketingPct / 100;
            uint256 lp = fees - marketing;

            if (marketing > 0) super._transfer(from, marketingWallet, marketing);
            if (lp > 0) super._transfer(from, address(this), lp);
        }

        super._transfer(from, to, amount - fees);
    }

    // Funciones owner
    function setPair(address _pair) external onlyOwner { pair = _pair; }
    function disableAntiBot() external onlyOwner { antiBot = false; }
    function setTaxes(uint256 _buy, uint256 _sell) external onlyOwner {
        buyTax = _buy;
        sellTax = _sell;
    }
}
