// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity ^0.6.0;

contract BirdToken is ERC20, Ownable {
    string constant NAME = "Bird.Money";
    string constant SYMBOL = "BIRD";
    uint8 constant DECIMALS = 18;
    uint256 constant TOTAL_SUPPLY = 900_000 * 10**uint256(DECIMALS);

    constructor() public ERC20(NAME, SYMBOL) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
