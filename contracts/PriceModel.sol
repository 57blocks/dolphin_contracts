// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import { IPriceModel } from "./interfaces/IPriceModel.sol";
import { ABDKMath64x64 } from "./library/ABDKMath64x64.sol";

contract PriceModel is IPriceModel {
    uint256 public constant BASE_PERCISION = 1e18;

    // int128 public immutable FP_MAGIC_NUMBER1 = ABDKMath64x64.divi(319381530000000000, int256(BASE_PERCISION));
    // int128 public immutable FP_MAGIC_NUMBER2 = ABDKMath64x64.divi(-356563782000000000, int256(BASE_PERCISION));
    // int128 public immutable FP_MAGIC_NUMBER3 = ABDKMath64x64.divi(1781477937000000000, int256(BASE_PERCISION));
    // int128 public immutable FP_MAGIC_NUMBER4 = ABDKMath64x64.divi(-1821255978000000000, int256(BASE_PERCISION));
    // int128 public immutable FP_MAGIC_NUMBER5 = ABDKMath64x64.divi(1330274429000000000, int256(BASE_PERCISION));
    // int128 public immutable FP_P = ABDKMath64x64.divi(231641900000000000, int256(BASE_PERCISION));
    // int128 public immutable PI = ABDKMath64x64.divi(3141592653589793238, int256(BASE_PERCISION));
    // int128 public immutable MEAN = ABDKMath64x64.fromUInt(2500);
    // int128 public immutable STD = ABDKMath64x64.fromUInt(700);

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        return (curve(supply + amount) - curve(supply)) / BASE_PERCISION / BASE_PERCISION / 50_000;
    }

    function curve(uint256 x) public pure returns (uint256) {
        return x == 0 ? 0 : (x * x * x);
    }
}
