// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract RemixingNFT is Ownable, ERC721Enumerable {
    uint256 nextTokenId = 1;
    mapping(uint256 => string) public tokenUri;

    constructor() Ownable(msg.sender) ERC721("RemixingNFT", "RMX") {}

    function mint(address to, string calldata uri) external onlyOwner returns (uint256 tokenId) {
        _mint(to, nextTokenId);
        tokenId = nextTokenId;
        tokenUri[tokenId] = uri;
        ++nextTokenId;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return tokenUri[tokenId];
    }
}
