// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IPriceModelSingle } from "./interfaces/IPriceModelSingle.sol";
import { IMarketSingle } from "./interfaces/IMarketSingle.sol";
import { ILicenseTemplate } from "./interfaces/story/ILicenseTemplate.sol";
import { StoryHelper } from "./StoryHelper.sol";
import { DolphinRemixNFT } from "./DolphinRemixNFT.sol";

contract DolphinIPMarket is IMarketSingle, Ownable, ERC1155 {
    string public constant name = "Dolphin";
    string public constant symbol = "DOL";
    uint256 public constant PERCENT_DIVISOR = 10_000;
    uint256 public constant PREMINT = 1;

    uint256 public ipAssetIndex = 1;
    IPriceModelSingle public defaultPriceModel;
    StoryHelper public storyHelper;
    DolphinRemixNFT public remixNFT;
    Fee public fees = Fee(2, 0, 0.00001 ether, 1000);
    mapping(address => uint256) public ipIdToAssetId;
    mapping(uint256 => address) public assetIdToIpId;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public poolLiquidity;
    mapping(address => uint256) public remixFloorPrice;

    constructor(address _storyHelper, address _priceModel) Ownable(msg.sender) ERC1155("") {
        remixNFT = new DolphinRemixNFT();
        storyHelper = StoryHelper(_storyHelper);
        defaultPriceModel = IPriceModelSingle(_priceModel);
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
        emit Trade(TradeType.Mint, ipId, newAssetId, msg.sender, PREMINT, 0, 0);
    }

    function getBuyPrice(address ipId) public view returns (uint256 price) {
        uint256 assetId = ipIdToAssetId[ipId];
        price = defaultPriceModel.getPrice(totalSupply[assetId]);
        uint256 floorPrice = remixFloorPrice[ipId];
        if (floorPrice > 0) {
            price += floorPrice;
        }
    }

    function getSellPrice(address ipId) public view returns (uint256 price) {
        uint256 assetId = ipIdToAssetId[ipId];
        price = defaultPriceModel.getPrice(totalSupply[assetId] - PREMINT);
        uint256 floorPrice = remixFloorPrice[ipId];
        if (floorPrice > 0) {
            price += floorPrice;
        }
    }

    function getBuyPriceAfterFee(address ipId) public view returns (uint256) {
        uint256 price = getBuyPrice(ipId);
        (, , uint256 totalFee) = _calcTradingFees(price);
        return price + totalFee;
    }

    function getSellPriceAfterFee(address ipId) public view returns (uint256) {
        uint256 price = getSellPrice(ipId);
        (, , uint256 totalFee) = _calcTradingFees(price);
        return price - totalFee;
    }

    function buy(address ipId) public payable {
        require(checkListed(ipId), "IP is not listed");
        uint256 price = getBuyPrice(ipId);
        (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) = _calcTradingFees(price);
        uint256 priceAfterFee = price + totalFee;
        require(msg.value >= priceAfterFee, "Insufficient payment");
        uint256 assetId = ipIdToAssetId[ipId];
        totalSupply[assetId] += 1;
        poolLiquidity[assetId] += price;
        _mint(msg.sender, assetId, 1, "");
        emit Trade(TradeType.Buy, ipId, assetId, msg.sender, 1, price, creatorFee);
        (bool creatorFeeSent, ) = payable(storyHelper.getIpOwner(ipId)).call{ value: creatorFee }("");
        require(creatorFeeSent, "Failed to send creator fee");
        if (protocolFee > 0) {
            (bool protocolFeeSent, ) = payable(owner()).call{ value: protocolFee }("");
            require(protocolFeeSent, "Failed to send protocol fee");
        }

        if (msg.value > priceAfterFee) {
            (bool refunded, ) = payable(msg.sender).call{ value: msg.value - priceAfterFee }("");
            require(refunded, "Failed to refund excess payment");
        }
    }

    function sell(address ipId) public {
        require(checkListed(ipId), "IP is not listed");
        uint256 assetId = ipIdToAssetId[ipId];
        require(balanceOf(msg.sender, assetId) >= 1, "Insufficient balance");
        uint256 supply = totalSupply[assetId];
        require(supply - 1 >= PREMINT, "Supply not allowed below premint amount");
        uint256 price = getSellPrice(ipId);
        (uint256 creatorFee, uint256 protocolFee, uint256 totalFee) = _calcTradingFees(price);
        _burn(msg.sender, assetId, 1);
        totalSupply[assetId] = supply - 1;
        poolLiquidity[assetId] -= price;
        emit Trade(TradeType.Sell, ipId, assetId, msg.sender, 1, price, creatorFee);
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
        return remix(parentIpId, licenseTemplate, licenseTermsId, storyHelper.getIpUri(parentIpId));
    }

    function remix(
        address parentIpId,
        address licenseTemplate,
        uint256 licenseTermsId,
        string memory ipUri
    ) public returns (address childIpId) {
        require(checkListed(parentIpId), "IP is not listed");
        require(
            storyHelper.hasIpAttachedLicenseTerm(parentIpId, licenseTemplate, licenseTermsId),
            "IP does not have the license"
        );
        // @dev Story will checks that parent IP is not disputed
        // require(!storyHelper.isDisputed(parentIpId), "IP is disputed");
        uint256 parentAssetId = ipIdToAssetId[parentIpId];
        require(balanceOf(msg.sender, parentAssetId) >= PREMINT, "Insufficient balance");
        // Register childIP
        uint256 tokenId = remixNFT.mint(address(this), ipUri);
        childIpId = storyHelper.ipAssetRegistry().register(block.chainid, address(remixNFT), tokenId);
        // Calc minting fee
        (address policy, , uint256 mintingLicenseFee, address currencyToken) = ILicenseTemplate(licenseTemplate)
            .getRoyaltyPolicy(licenseTermsId);
        {
            uint256 configFee = storyHelper.getLicensingConfigFee(
                parentIpId,
                childIpId,
                licenseTemplate,
                licenseTermsId
            );
            if (configFee > 0) {
                mintingLicenseFee = configFee;
            }
        }

        if (mintingLicenseFee > 0) {
            IERC20(currencyToken).transferFrom(msg.sender, address(this), mintingLicenseFee);
            IERC20(currencyToken).approve(policy, mintingLicenseFee);
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
        uint256 sellPrice = getSellPrice(parentIpId);
        _burn(msg.sender, parentAssetId, 1);
        totalSupply[parentAssetId] -= 1;
        poolLiquidity[parentAssetId] -= sellPrice;
        emit Remix(parentIpId, childIpId, msg.sender, licenseTemplate, licenseTermsId, sellPrice, 0);
        uint256 childAssetId = _register(childIpId);
        emit List(childIpId, childAssetId, msg.sender);
        poolLiquidity[childAssetId] += sellPrice;
        remixFloorPrice[childIpId] = sellPrice;
        emit Trade(TradeType.Mint, childIpId, childAssetId, msg.sender, PREMINT, sellPrice, 0);
        remixNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function checkListed(address ipId) public view returns (bool) {
        return ipIdToAssetId[ipId] != 0;
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(id < ipAssetIndex, "URI query for nonexistent token");
        address ipId = assetIdToIpId[id];
        return storyHelper.getIpUri(ipId);
    }

    function balanceOf(address account, address ipId) public view returns (uint256) {
        return balanceOf(account, ipIdToAssetId[ipId]);
    }

    function balanceOfBatch(
        address[] memory accounts,
        address[] memory ipIds
    ) public view virtual returns (uint256[] memory) {
        uint256[] memory assetIds = new uint256[](ipIds.length);
        for (uint256 i = 0; i < ipIds.length; ++i) {
            assetIds[i] = ipIdToAssetId[ipIds[i]];
        }
        return balanceOfBatch(accounts, assetIds);
    }

    // Admin functions
    function setFees(uint64 creatorFee, uint64 protocolFee, uint64 listingFee, uint64 remixingFee) external onlyOwner {
        fees = Fee(creatorFee, protocolFee, listingFee, remixingFee);
    }

    function setStoryHelper(address _storyHelper) external onlyOwner {
        storyHelper = StoryHelper(_storyHelper);
    }

    function setDefaultPriceModel(address _defaultPriceModel) external onlyOwner {
        defaultPriceModel = IPriceModelSingle(_defaultPriceModel);
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
        totalSupply[newAssetId] += PREMINT;
        ipAssetIndex = newAssetId + 1;
        _mint(msg.sender, newAssetId, PREMINT, "");
        return newAssetId;
    }
}
