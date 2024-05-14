// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPriceModel } from "./interfaces/IPriceModel.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { StoryHelper } from "./StoryHelper.sol";

contract MarketCore is IMarket, Ownable, ERC1155 {
    uint256 public constant PERCENT_DVISOR = 10_000;
    uint256 public constant CREATOR_PREMINT = 1 ether;

    uint256 public ipAssetIndex = 1;
    IPriceModel public defaultPriceModel;
    StoryHelper public storyHelper;
    Fee public fees = Fee(2, 0, 0.00001 ether, 1000);
    mapping(address => uint256) public ipIdToAssetId;
    mapping(uint256 => address) public assetIdToIpId;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public poolLiquidity;
    mapping(address => uint256) public remixFloorPrice;

    constructor() Ownable(msg.sender) {}

    function listBatch(address[] calldata ipIds) public {
        for (uint256 i = 0; i < ipIds.length; i++) {
            list(ipIds[i]);
        }
    }

    function list(address ipId) public {
        require(!_checkListed(ipId), "IP already listed");
        require(storyHelper.isIP(ipId), "Address is not an IP");
        require(!storyHelper.isDisputed(ipId), "IP is disputed");
        require(msg.sender == storyHelper.getIpOwner(ipId), "Caller is not the owner");
        uint256 newAssetId = ipAssetIndex;
        assetIdToIpId[newAssetId] = ipId;
        ipIdToAssetId[ipId] = newAssetId;
        totalSupply[newAssetId] += CREATOR_PREMINT;
        ipAssetIndex = newAssetId + 1;
        _mint(msg.sender, newAssetId, CREATOR_PREMINT, "");
        emit List(ipId, newAssetId, msg.sender);
        emit Trade(TradeType.Mint, ipId, newAssetId, msg.sender, CREATOR_PREMINT, 0, 0);
    }

    function getBuyPrice(address ipId, uint256 amount) public view returns (uint256) {
        uint256 assetId = ipIdToAssetId[ipId];
        return this.getBuyPrice(assetId, amount);
    }

    function getBuyPrice(uint256 assetId, uint256 amount) public view returns (uint256) {
        return defaultPriceModel.getPrice(totalSupply[assetId], amount);
    }

    function getSellPrice(address ipId, uint256 amount) public view returns (uint256) {
        uint256 assetId = ipIdToAssetId[ipId];
        return this.getSellPrice(assetId, amount);
    }

    function getSellPrice(uint256 assetId, uint256 amount) public view returns (uint256) {
        return defaultPriceModel.getPrice(totalSupply[assetId] - amount, amount);
    }

    function getBuyPriceAfterFee(address ipId, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(ipId, amount);
        (, , uint256 totalFee) = _calcTradingFees(price);
        return price + totalFee;
    }

    function getSellPriceAfterFee(address ipId, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(ipId, amount);
        (, , uint256 totalFee) = _calcTradingFees(price);
        return price - totalFee;
    }

    function buy(address ipId, uint256 amount) public payable {
        require(_checkListed(ipId), "IP does not exist");
        uint256 assetId = ipIdToAssetId[ipId];
        uint256 price = getBuyPrice(assetId, amount);
        (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) = _calcTradingFees(price);
        require(msg.value >= price + totalFee, "Insufficient payment");
        totalSupply[assetId] += amount;
        poolLiquidity[assetId] += price;
        _mint(msg.sender, assetId, amount, "");
        emit Trade(TradeType.Buy, ipId, assetId, msg.sender, amount, price, creatorFee);
        (bool creatorFeeSent, ) = payable(storyHelper.getIpOwner(ipId)).call{ value: creatorFee }("");
        require(creatorFeeSent, "Failed to send creator fee");
        if (protocolFee > 0) {
            (bool protocolFeeSent, ) = payable(owner()).call{ value: protocolFee }("");
            require(protocolFeeSent, "Failed to send protocol fee");
        }
    }

    function sell(address ipId, uint256 amount) public {
        require(_checkListed(ipId), "IP does not exist");
        uint256 assetId = ipIdToAssetId[ipId];
        require(balanceOf[msg.sender][assetId] >= amount, "Insufficient balance");
        uint256 supply = totalSupply[assetId];
        require(supply - amount >= CREATOR_PREMINT, "Supply not allowed below premint amount");
        uint256 price = getSellPrice(assetId, amount);
        (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) = _calcTradingFees(price);
        _burn(msg.sender, assetId, amount);
        totalSupply[assetId] = supply - amount;
        poolLiquidity[assetId] -= price;
        emit Trade(TradeType.Sell, ipId, assetId, msg.sender, amount, price, creatorFee);
        (bool sent, ) = payable(msg.sender).call{ value: price - totalFee }("");
        (bool creatorFeeSent, ) = payable(storyHelper.getIpOwner(ipId)).call{ value: creatorFee }("");
        require(sent && creatorFeeSent, "Failed to send ether");
        if (protocolFee > 0) {
            (bool protocolFeeSent, ) = payable(owner()).call{ value: protocolFee }("");
            require(protocolFeeSent, "Failed to send protocol fee");
        }
    }

    function remix(address ipId) public returns (address childIpId) {
        return ipId;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id < ipAssetIndex, "URI query for nonexistent token");
        address ipId = assetIdToIpId[id];
        return storyHelper.getIpUri(ipId);
    }

    function _checkListed(address ipId) internal view returns (bool) {
        return ipIdToAssetId[ipId] != 0;
    }

    function _calcTradingFees(
        uint256 price
    ) internal view returns (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) {
        Fee memory _fees = fees;
        uint256 creatorFeeBp = _fees.creatorFee;
        totalFee = (price * creatorFeeBp) / PERCENT_DVISOR;
        creatorFee = totalFee;
        uint256 protocolFeeBp = _fees.protocolFee;
        protocolFee = 0;
        if (protocolFeeBp > 0) {
            protocolFee = (totalFee * protocolFeeBp) / PERCENT_DVISOR;
            creatorFee = totalFee - protocolFee;
        }
    }
}
