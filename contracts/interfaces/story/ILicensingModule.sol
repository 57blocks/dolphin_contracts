// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { Licensing } from "./Licensing.sol";

/// @title ILicensingModule
/// @notice This interface defines the entry point for users to manage licenses in the Story Protocol.
/// It defines the workflow of license actions and coordinates among all license components and dependent components,
/// like RoyaltyModule.
/// The Licensing Module is responsible for attaching license terms to an IP, minting license tokens,
/// and registering derivatives.
interface ILicensingModule {
    /// @notice Emitted when new license terms are attached to an IP.
    /// @param caller The address of the caller.
    /// @param ipId The IP ID.
    /// @param licenseTemplate The address of the license template.
    /// @param licenseTermsId The ID of the license terms in the license template.
    event LicenseTermsAttached(
        address indexed caller,
        address indexed ipId,
        address licenseTemplate,
        uint256 licenseTermsId
    );

    /// @notice Emitted when license tokens are minted.
    /// @param caller The address of the caller.
    /// @param licensorIpId The parent IP ID.
    /// @param licenseTemplate The address of the license template.
    /// @param licenseTermsId The ID of the license terms.
    /// @param amount The amount of license tokens minted.
    /// @param receiver The address of the receiver.
    /// @param startLicenseTokenId The start ID of the minted license tokens.
    event LicenseTokensMinted(
        address indexed caller,
        address indexed licensorIpId,
        address licenseTemplate,
        uint256 indexed licenseTermsId,
        uint256 amount,
        address receiver,
        uint256 startLicenseTokenId
    );

    /// @notice Emitted when a derivative IP is registered.
    /// @param caller The address of the caller.
    /// @param childIpId The derivative IP ID.
    /// @param licenseTokenIds The IDs of the license tokens.
    /// @param parentIpIds The parent IP IDs.
    /// @param licenseTermsIds The IDs of the license terms.
    /// @param licenseTemplate The address of the license template.
    event DerivativeRegistered(
        address indexed caller,
        address indexed childIpId,
        uint256[] licenseTokenIds,
        address[] parentIpIds,
        uint256[] licenseTermsIds,
        address licenseTemplate
    );

    /// @notice Attaches license terms to an IP.
    /// the function must be called by the IP owner or an authorized operator.
    /// @param ipId The IP ID.
    /// @param licenseTemplate The address of the license template.
    /// @param licenseTermsId The ID of the license terms.
    function attachLicenseTerms(address ipId, address licenseTemplate, uint256 licenseTermsId) external;

    /// @notice Mints license tokens for the license terms attached to an IP.
    /// The license tokens are minted to the receiver.
    /// The license terms must be attached to the IP before calling this function.
    /// But it can mint license token of default license terms without attaching the default license terms,
    /// since it is attached to all IPs by default.
    /// IP owners can mint license tokens for their IPs for arbitrary license terms
    /// without attaching the license terms to IP.
    /// It might require the caller pay the minting fee, depending on the license terms or configured by the iP owner.
    /// The minting fee is paid in the minting fee token specified in the license terms or configured by the IP owner.
    /// IP owners can configure the minting fee of their IPs or
    /// configure the minting fee module to determine the minting fee.
    /// IP owners can configure the receiver check module to determine the receiver of the minted license tokens.
    /// @param licensorIpId The licensor IP ID.
    /// @param licenseTemplate The address of the license template.
    /// @param licenseTermsId The ID of the license terms within the license template.
    /// @param amount The amount of license tokens to mint.
    /// @param receiver The address of the receiver.
    /// @param royaltyContext The context of the royalty.
    /// @return startLicenseTokenId The start ID of the minted license tokens.
    function mintLicenseTokens(
        address licensorIpId,
        address licenseTemplate,
        uint256 licenseTermsId,
        uint256 amount,
        address receiver,
        bytes calldata royaltyContext
    ) external returns (uint256 startLicenseTokenId);

    /// @notice Registers a derivative directly with parent IP's license terms, without needing license tokens,
    /// and attaches the license terms of the parent IPs to the derivative IP.
    /// The license terms must be attached to the parent IP before calling this function.
    /// All IPs attached default license terms by default.
    /// The derivative IP owner must be the caller or an authorized operator.
    /// @param childIpId The derivative IP ID.
    /// @param parentIpIds The parent IP IDs.
    /// @param licenseTermsIds The IDs of the license terms that the parent IP supports.
    /// @param licenseTemplate The address of the license template of the license terms Ids.
    /// @param royaltyContext The context of the royalty.
    function registerDerivative(
        address childIpId,
        address[] calldata parentIpIds,
        uint256[] calldata licenseTermsIds,
        address licenseTemplate,
        bytes calldata royaltyContext
    ) external;

    /// @notice Registers a derivative with license tokens.
    /// the derivative IP is registered with license tokens minted from the parent IP's license terms.
    /// the license terms of the parent IPs issued with license tokens are attached to the derivative IP.
    /// the caller must be the derivative IP owner or an authorized operator.
    /// @param childIpId The derivative IP ID.
    /// @param licenseTokenIds The IDs of the license tokens.
    /// @param royaltyContext The context of the royalty.
    function registerDerivativeWithLicenseTokens(
        address childIpId,
        uint256[] calldata licenseTokenIds,
        bytes calldata royaltyContext
    ) external;

    /// @notice Sets the licensing configuration for a specific license terms of an IP.
    /// If both licenseTemplate and licenseTermsId are not specified then the licensing config apply
    /// to all licenses of given IP.
    /// @param ipId The address of the IP for which the configuration is being set.
    /// @param licenseTemplate The address of the license template used.
    /// If not specified, the configuration applies to all licenses.
    /// @param licenseTermsId The ID of the license terms within the license template.
    /// If not specified, the configuration applies to all licenses.
    /// @param licensingConfig The licensing configuration for the license.
    function setLicensingConfig(
        address ipId,
        address licenseTemplate,
        uint256 licenseTermsId,
        Licensing.LicensingConfig memory licensingConfig
    ) external;
}
