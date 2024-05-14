// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IPriceModel {
    function getPrice(uint256 _supply, uint256 _amount) external view returns (uint256 price);
}
