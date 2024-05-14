// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IIPAssetRegistry } from "./interfaces/IIPAssetRegistry.sol";
import { IIPAccount } from "./interfaces/IIPAccount.sol";
import { IDisputeModule } from "./interfaces/IDisputeModule.sol";

contract StoryHelper {
    IIPAssetRegistry immutable ipAssetRegistry = IIPAssetRegistry(0xd43fE0d865cb5C26b1351d3eAf2E3064BE3276F6);
    IDisputeModule immutable disputeModule = IDisputeModule(0xEB7B1dd43B81A7be1fA427515a2b173B454A9832);

    function getIpOwner(address ipId) public view returns (address) {
        return IIPAccount(ipId).owner();
    }

    function getIpUri(address ipId) public view returns (string memory) {
        (, address _tokenContract, uint256 _tokenId) = IIPAccount(ipId).token();
        return IERC721Metadata(_tokenContract).tokenURI(_tokenId);
    }

    function isIP(address ipId) public view returns (bool) {
        return ipAssetRegistry.isRegistered(ipId);
    }

    function isDisputed(address ipId) public view returns (bool) {
        return disputeModule.isIpTagged(ipId);
    }
}
