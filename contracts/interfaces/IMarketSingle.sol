// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IMarketSingle {
    event List(address indexed ipId, uint256 indexed assetId, address indexed sender);
    event Remix(
        address indexed parentIpId,
        address indexed childIpId,
        address indexed sender,
        address llicenseTemplate,
        uint256 licenseTermsId,
        uint256 floorValue,
        uint256 fee
    );
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
        Mint, // 0
        Buy,
        Sell,
        Remix
    }

    function buy(address ipId) external payable;

    function sell(address ipId) external;
}
