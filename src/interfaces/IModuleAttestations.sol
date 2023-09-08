// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
    event ModuleApplicationSuccess(address module, uint256 fee);
    event AttesterAdded(address attester);
    event AttesterRemoved(address attester);
    event AttestationConfigSet(uint256 fee, bytes32 schemaId, uint8 threshold);
    event ClaimedCut(address module, bytes32 uid, address claimer);

    function applyForAttestations() external payable returns (bool success);

    function addAttester(address attester) external;

    function removeAttester(address attester) external;

    function addAttesters(address[] calldata attesters) external;

    function removeAttesters(address[] calldata attesters) external;

    function setAttestationConfig(uint256 fee, bytes32 schemaId, uint8 threshold) external;

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
