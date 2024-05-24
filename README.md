# Dolphin IP Asset Exchange Contracts

Welcome to the Dolphin IP Asset Exchange Contracts repository! This smart contract allows users to list, buy, sell, and remix IP assets on a decentralized marketplace. Below, you'll find a detailed guide on the main functions available in the contract, along with usage examples and explanations.

## Table of Contents

- [Dolphin IP Asset Exchange Contracts](#dolphin-ip-asset-exchange-contracts)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Main Functions](#main-functions)
    - [list](#list)
    - [buy](#buy)
    - [sell](#sell)
    - [remix](#remix)
  - [Getting Started](#getting-started)
  - [Examples](#examples)

## Introduction

The Dolphin IP Asset Exchange Contracts provide a way for creators and IP owners to manage their intellectual property assets on the blockchain. With this contract, you can list your IP assets for sale, buy shares of listed IP assets, sell your shares, and create derivative works from existing IP assets.

## Main Functions

### list

**Function Signature:**
```
function list(address ipId) public
```
**Description:**

If you are the IP owner, you can list your IP asset on the marketplace.

**Parameters:**

 - ipId (address): The unique identifier of the IP asset.

**Usage:**
```
// Example usage
dolphinContract.list(0xYourIpAssetAddress);
```
### buy

**Function Signature:**
```
function buy(address ipId) public payable
```

**Description:**

If the IP has been listed by the owner, you can buy shares from the IP asset.

**Parameters:**

- ipId (address): The unique identifier of the IP asset.

**Usage:**
```
// Example usage
dolphinContract.buy{value: 1 ether}(0xYourIpAssetAddress);
```
### sell
**Function Signature:**
```
function sell(address ipId) public
```

**Description:**

You can sell your IP share at any time.

**Parameters:**

- ipId (address): The unique identifier of the IP asset.

**Usage:**

```
// Example usage
dolphinContract.sell(0xYourIpAssetAddress);
```
### remix
**Function Signature:**
```
function remix(
    address parentIpId,
    address licenseTemplate,
    uint256 licenseTermsId,
    string memory ipUri
) public
```
**Description:**

You can choose a listed IP to create a remix, minting a derivative with a higher floor price.

**Parameters:**

- parentIpId (address): The address of the parent IP.
- licenseTemplate (address): The address of the license template.
- licenseTermsId (uint256): The ID of the license terms.
- ipUri (string memory): The URI of the new IP.

**Usage:**
```
// Example usage
dolphinContract.remix(0xParentIpAddress, 0xLicenseTemplateAddress, 101, "ipfs://new-ip-uri");
```

## Getting Started
To get started with the Dolphin IP Asset Exchange Contracts, you'll need to have a basic understanding of Solidity and smart contract development. Here are the steps to set up and deploy the contract:

**1. Clone the repository:**

    git clone https://github.com/57blocks/dolphin-contracts.git
    cd dolphin-contracts


**2. Install dependencies:**

    npm install

**3. Compile the contract:**

    npm run compile

**4. Deploy the contract:**

    npx hardhat ignition deploy ./ignition/modules/* --network your-network

## Examples
Here are some examples of how to interact with the Dolphin IP Asset Exchange Contracts using JavaScript and the Web3 library:

**Listing an IP asset**
```
const ipId = "0xYourIpAssetAddress";
await dolphinContract.list(ipId);
```

**Buying an IP share**
```
const ipId = "0xYourIpAssetAddress";
await dolphinContract.buy(ipId, { value: ethers.parseEther("1") });
```
**Selling an IP share**
```
const ipId = "0xYourIpAssetAddress";
await dolphinContract.sell(ipId);
```
**Remixing an IP asset**
```
const parentIpId = "0xParentIpAddress";
const licenseTemplate = "0xLicenseTemplateAddress";
const licenseTermsId = 101;
const ipUri = "ipfs://new-ip-uri";
await dolphinContract.remix(parentIpId, licenseTemplate, licenseTermsId, ipUri);