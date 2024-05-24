// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.24;

import { IPriceModel } from "./interfaces/IPriceModel.sol";
import { ABDKMath64x64 } from "./library/ABDKMath64x64.sol";

contract PriceModelSingle {
    uint256 public constant BASE_PERCISION = 1 ether;
    int128 private immutable FP_ONE = ABDKMath64x64.fromUInt(1);
    int128 private immutable FP_TWO = ABDKMath64x64.fromUInt(2);
    int128 private immutable FP_MAGIC_NUMBER1 = ABDKMath64x64.divi(319381530000000000, int256(BASE_PERCISION));
    int128 private immutable FP_MAGIC_NUMBER2 = ABDKMath64x64.divi(-356563782000000000, int256(BASE_PERCISION));
    int128 private immutable FP_MAGIC_NUMBER3 = ABDKMath64x64.divi(1781477937000000000, int256(BASE_PERCISION));
    int128 private immutable FP_MAGIC_NUMBER4 = ABDKMath64x64.divi(-1821255978000000000, int256(BASE_PERCISION));
    int128 private immutable FP_MAGIC_NUMBER5 = ABDKMath64x64.divi(1330274429000000000, int256(BASE_PERCISION));
    int128 private immutable FP_P = ABDKMath64x64.divi(231641900000000000, int256(BASE_PERCISION));
    int128 private immutable PI = ABDKMath64x64.divi(3141592653589793238, int256(BASE_PERCISION));
    int128 private immutable INV_SQRT2PI =
        ABDKMath64x64.inv(ABDKMath64x64.sqrt(ABDKMath64x64.mul(PI, ABDKMath64x64.fromUInt(2))));
    int128 private immutable MEAN = ABDKMath64x64.fromUInt(2500);
    int128 private immutable STD = ABDKMath64x64.fromUInt(700);

    function getPrice(uint256 supply) public view returns (uint256) {
        return supply == 0 ? 0 : curve(supply);
    }

    function curve(uint256 x) public view returns (uint256) {
        int128 supply = ABDKMath64x64.fromUInt(x);
        int128 z = ABDKMath64x64.div(ABDKMath64x64.sub(supply, MEAN), STD);
        int128 a = ABDKMath64x64.abs(z);
        int128 t = ABDKMath64x64.inv(ABDKMath64x64.add(FP_ONE, ABDKMath64x64.mul(a, FP_P)));
        int128 w1 = 0;
        {
            int128 b4_add_t_mul_b5 = ABDKMath64x64.add(FP_MAGIC_NUMBER4, ABDKMath64x64.mul(t, FP_MAGIC_NUMBER5));
            int128 b3_add_t_mul_prev = ABDKMath64x64.add(FP_MAGIC_NUMBER3, ABDKMath64x64.mul(t, b4_add_t_mul_b5));
            int128 b2_add_t_mul_prev = ABDKMath64x64.add(FP_MAGIC_NUMBER2, ABDKMath64x64.mul(t, b3_add_t_mul_prev));
            int128 b1_add_t_mul_prev = ABDKMath64x64.add(FP_MAGIC_NUMBER1, ABDKMath64x64.mul(t, b2_add_t_mul_prev));
            w1 = ABDKMath64x64.mul(t, b1_add_t_mul_prev);
        }
        int128 expasqr = ABDKMath64x64.exp(ABDKMath64x64.neg(ABDKMath64x64.div(ABDKMath64x64.pow(a, 2), FP_TWO)));
        int128 tmp = ABDKMath64x64.mul(ABDKMath64x64.mul(INV_SQRT2PI, expasqr), w1);
        int128 w = ABDKMath64x64.sub(FP_ONE, tmp);
        uint256 price = ABDKMath64x64.mulu(w, BASE_PERCISION);
        if (z < 0) {
            return BASE_PERCISION - price;
        }
        return price;
    }
}
