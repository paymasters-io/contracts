// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SchemaRecord, ISchemaRegistry} from "@eas/contracts/ISchemaRegistry.sol";
import {AttestationRequestData, AttestationRequest, RevocationRequestData, RevocationRequest, Attestation} from "@eas/contracts/IEAS.sol";

enum AttestationStatus {
    None,
    Pending,
    Approved,
    Rejected
}

struct Attestations {
    uint192 attestationCount; // excludes revocations
    uint64 timestamp;
    uint256 fee;
    AttestationStatus attestationStatus;
}

struct MultiAttestClaim {
    address module;
    bytes32 uid;
}

error AlreadyAttested();
error NotTheAttester(address attester, bytes32 uid);
error NotUnlocked();

interface IModuleAttestations {
    function applyForAttestations() external payable returns (bool success);

    function addAttester(address attester) external;

    function removeAttester(address attester) external;

    function addAttesters(address[] calldata attesters) external;

    function removeAttesters(address[] calldata attesters) external;

    function setAttestationConfig(uint8 threshold, uint256 fee) external;

    function getAttestationFee() external view returns (uint256);

    function attestationResolved(address module) external view returns (bool);

    function claimAttestersCut(address module, bytes32 uid) external;

    function multiClaimAttestersCut(MultiAttestClaim[] calldata claims) external;

    function attestEAS(
        address name,
        address moduleAddress,
        address manager,
        bool verified,
        bool safe
    ) external payable;

    function revokeEAS(bytes32 uuid) external payable;
}
