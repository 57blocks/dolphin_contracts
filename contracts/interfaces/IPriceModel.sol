// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPriceModel {
    function getPrice(uint256 supply, uint256 amount) external view returns (uint256 price);
}
