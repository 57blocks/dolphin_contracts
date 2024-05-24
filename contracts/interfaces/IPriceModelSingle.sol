// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPriceModelSingle {
    function getPrice(uint256 supply) external view returns (uint256 price);
}
