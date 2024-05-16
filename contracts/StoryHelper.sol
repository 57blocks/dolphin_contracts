// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IIPAssetRegistry } from "./interfaces/story/IIPAssetRegistry.sol";
import { IIPAccount } from "./interfaces/story/IIPAccount.sol";
import { IDisputeModule } from "./interfaces/story/IDisputeModule.sol";
import { ILicensingModule } from "./interfaces/story/ILicensingModule.sol";
import { ILicenseRegistry } from "./interfaces/story/ILicenseRegistry.sol";
import { Licensing } from "./interfaces/story/Licensing.sol";
import { ILicensingHook } from "./interfaces/story/ILicensingHook.sol";

contract StoryHelper {
    IIPAssetRegistry public immutable ipAssetRegistry = IIPAssetRegistry(0xd43fE0d865cb5C26b1351d3eAf2E3064BE3276F6);
    ILicenseRegistry public immutable licenseRegistry = ILicenseRegistry(0x4f4b1bf7135C7ff1462826CCA81B048Ed19562ed);
    ILicensingModule public immutable licensingModule = ILicensingModule(0xe89b0EaA8a0949738efA80bB531a165FB3456CBe);
    IDisputeModule public immutable disputeModule = IDisputeModule(0xEB7B1dd43B81A7be1fA427515a2b173B454A9832);

    function getIpOwner(address ipId) public view returns (address) {
        return IIPAccount(ipId).owner();
    }

    function getIpUri(address ipId) public view returns (string memory) {
        (, address _tokenContract, uint256 _tokenId) = IIPAccount(ipId).token();
        return IERC721Metadata(_tokenContract).tokenURI(_tokenId);
    }

    function getLicensingConfigFee(
        address ipId,
        address childIpId,
        address licenseTemplate,
        uint256 licenseTermsId
    ) public returns (uint256) {
        Licensing.LicensingConfig memory config = licenseRegistry.getLicensingConfig(
            ipId,
            licenseTemplate,
            licenseTermsId
        );

        if (!config.isSet) {
            return 0;
        } else if (config.licensingHook == address(0)) {
            return config.mintingFee;
        } else {
            return
                ILicensingHook(config.licensingHook).beforeRegisterDerivative(
                    msg.sender,
                    childIpId,
                    ipId,
                    licenseTemplate,
                    licenseTermsId,
                    config.hookData
                );
        }
    }

    function isIP(address ipId) public view returns (bool) {
        return ipAssetRegistry.isRegistered(ipId);
    }

    function isDisputed(address ipId) public view returns (bool) {
        return disputeModule.isIpTagged(ipId);
    }

    function hasIpAttachedLicenseTerm(
        address ipId,
        address licenseTemplate,
        uint256 licenseTermsId
    ) public view returns (bool) {
        return licenseRegistry.hasIpAttachedLicenseTerms(ipId, licenseTemplate, licenseTermsId);
    }
}
