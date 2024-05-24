// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import { IPriceModel } from "./interfaces/IPriceModel.sol";

contract DefaultPriceModel is IPriceModel {
    uint256 public constant BASE_PERCISION = 1e18;

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        return (curve(supply + amount) - curve(supply)) / BASE_PERCISION / BASE_PERCISION / 50_000;
    }

    function curve(uint256 x) public pure returns (uint256) {
        return x == 0 ? 0 : (x * x * x);
    }
}
