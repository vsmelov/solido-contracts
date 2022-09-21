// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract MockUSDT is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("USDT", "USDT") {}
}
