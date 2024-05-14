// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IMarket {
    event List(address indexed ipId, uint256 indexed assetId, address indexed sender);
    event Trade(
        TradeType indexed tradeType,
        address indexed ipId,
        uint256 indexed assetId,
        address sender,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 fee
    );

    struct Fee {
        // BPS
        uint64 creatorFee;
        // BPS : a portion of creator fee
        uint64 protocolFee;
        // Fixed amount
        uint64 listingFee;
        // BPS
        uint64 remixingFee;
    }

    enum TradeType {
        Mint,
        Buy,
        Sell
    }

    function buy(address ipId, uint256 amount) external payable;

    function sell(address ipId, uint256 amount) external;
}
