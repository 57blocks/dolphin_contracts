// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC1155 } from "solmate/src/tokens/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPriceModel } from "./interfaces/IPriceModel.sol";
import { IMarket } from "./interfaces/IMarket.sol";
import { ILicenseTemplate } from "./interfaces/story/ILicenseTemplate.sol";
import { StoryHelper } from "./StoryHelper.sol";
import { RemixingNFT } from "./RemixingNFT.sol";

contract Market is IMarket, Ownable, ERC1155 {
    uint256 public constant PERCENT_DIVISOR = 10_000;
    uint256 public constant CREATOR_PREMINT = 1 ether;

    uint256 public ipAssetIndex = 1;
    IPriceModel public defaultPriceModel;
    StoryHelper public storyHelper;
    RemixingNFT public remixingNFT;
    Fee public fees = Fee(2, 0, 0.00001 ether, 1000);
    mapping(address => uint256) public ipIdToAssetId;
    mapping(uint256 => address) public assetIdToIpId;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public poolLiquidity;
    mapping(address => uint256) public remixFloorPrice;

    constructor() Ownable(msg.sender) {
        remixingNFT = new RemixingNFT();
    }

    function listBatch(address[] calldata ipIds) public {
        for (uint256 i = 0; i < ipIds.length; i++) {
            list(ipIds[i]);
        }
    }

    function list(address ipId) public {
        require(!checkListed(ipId), "IP already listed");
        require(storyHelper.isIP(ipId), "Address is not an IP");
        require(!storyHelper.isDisputed(ipId), "IP is disputed");
        require(msg.sender == storyHelper.getIpOwner(ipId), "Caller is not the owner");
        uint256 newAssetId = _register(ipId);
        emit List(ipId, newAssetId, msg.sender);
        emit Trade(TradeType.Mint, ipId, newAssetId, msg.sender, CREATOR_PREMINT, 0, 0);
    }

    function getBuyPrice(address ipId, uint256 amount) public view returns (uint256 price) {
        uint256 assetId = ipIdToAssetId[ipId];
        price = defaultPriceModel.getPrice(totalSupply[assetId], amount);
        uint256 floorPrice = remixFloorPrice[ipId];
        if (floorPrice > 0) {
            price += remixFloorPrice[ipId];
        }
    }

    function getSellPrice(address ipId, uint256 amount) public view returns (uint256 price) {
        uint256 assetId = ipIdToAssetId[ipId];
        price = defaultPriceModel.getPrice(totalSupply[assetId] - amount, amount);
        uint256 floorPrice = remixFloorPrice[ipId];
        if (floorPrice > 0) {
            price += remixFloorPrice[ipId];
        }
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
        require(checkListed(ipId), "IP is not listed");
        uint256 price = getBuyPrice(ipId, amount);
        (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) = _calcTradingFees(price);
        require(msg.value >= price + totalFee, "Insufficient payment");
        uint256 assetId = ipIdToAssetId[ipId];
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
        require(checkListed(ipId), "IP is not listed");
        uint256 assetId = ipIdToAssetId[ipId];
        require(balanceOf[msg.sender][assetId] >= amount, "Insufficient balance");
        uint256 supply = totalSupply[assetId];
        require(supply - amount >= CREATOR_PREMINT, "Supply not allowed below premint amount");
        uint256 price = getSellPrice(ipId, amount);
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

    function remix(
        address parentIpId,
        address licenseTemplate,
        uint256 licenseTermsId
    ) public returns (address childIpId) {
        require(checkListed(parentIpId), "IP is not listed");
        require(
            storyHelper.hasIpAttachedLicenseTerm(parentIpId, licenseTemplate, licenseTermsId),
            "IP does not have the license"
        );
        uint256 parentAssetId = ipIdToAssetId[parentIpId];
        require(balanceOf[msg.sender][parentAssetId] >= CREATOR_PREMINT, "Insufficient balance");
        // Register childIP
        uint256 tokenId = remixingNFT.mint(address(this), storyHelper.getIpUri(parentIpId));
        childIpId = storyHelper.ipAssetRegistry().register(block.chainid, address(remixingNFT), tokenId);
        storyHelper.licensingModule().attachLicenseTerms(childIpId, 0x260B6CB6284c89dbE660c0004233f7bB99B5edE7, 21);
        // Calc minting fee
        (, , uint256 mintingLicenseFee, address currencyToken) = ILicenseTemplate(licenseTemplate).getRoyaltyPolicy(
            licenseTermsId
        );
        if (mintingLicenseFee > 0) {
            IERC20(currencyToken).transferFrom(msg.sender, address(this), mintingLicenseFee);
            IERC20(currencyToken).approve(address(storyHelper.licensingModule()), mintingLicenseFee);
        }
        // Mint derivative
        {
            address[] memory _parents = new address[](1);
            _parents[0] = parentIpId;
            uint256[] memory _lids = new uint256[](1);
            _lids[0] = licenseTermsId;
            storyHelper.licensingModule().registerDerivative(childIpId, _parents, _lids, licenseTemplate, "");
        }
        // Burn parent key
        _burn(msg.sender, parentAssetId, CREATOR_PREMINT);
        totalSupply[parentAssetId] -= CREATOR_PREMINT;
        uint256 sellPrice = getSellPrice(parentIpId, CREATOR_PREMINT);
        poolLiquidity[parentAssetId] -= sellPrice;
        emit Remix(parentIpId, childIpId, msg.sender, sellPrice, 0);
        uint256 childAssetId = _register(childIpId);
        poolLiquidity[childAssetId] += sellPrice;
        remixFloorPrice[childIpId] = sellPrice;
        emit Trade(TradeType.Mint, childIpId, childAssetId, msg.sender, CREATOR_PREMINT, sellPrice, 0);
        remixingNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function checkListed(address ipId) public view returns (bool) {
        return ipIdToAssetId[ipId] != 0;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id < ipAssetIndex, "URI query for nonexistent token");
        address ipId = assetIdToIpId[id];
        return storyHelper.getIpUri(ipId);
    }

    function _calcTradingFees(
        uint256 price
    ) internal view returns (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) {
        Fee memory _fees = fees;
        uint256 creatorFeeBp = _fees.creatorFee;
        totalFee = (price * creatorFeeBp) / PERCENT_DIVISOR;
        creatorFee = totalFee;
        uint256 protocolFeeBp = _fees.protocolFee;
        protocolFee = 0;
        if (protocolFeeBp > 0) {
            protocolFee = (totalFee * protocolFeeBp) / PERCENT_DIVISOR;
            creatorFee = totalFee - protocolFee;
        }
    }

    function _register(address ipId) internal returns (uint256) {
        uint256 newAssetId = ipAssetIndex;
        assetIdToIpId[newAssetId] = ipId;
        ipIdToAssetId[ipId] = newAssetId;
        totalSupply[newAssetId] += CREATOR_PREMINT;
        ipAssetIndex = newAssetId + 1;
        _mint(msg.sender, newAssetId, CREATOR_PREMINT, "");
        return newAssetId;
    }
}
