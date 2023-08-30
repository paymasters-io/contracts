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
    uint256 attestationCount;
    AttestationStatus attestationStatus;
}

error AlreadyAttested();

interface IEASHelper {
    function addAttester(address attester) external;

    function removeAttester(address attester) external;

    function addAttesters(address[] calldata attesters) external;

    function removeAttesters(address[] calldata attesters) external;

    function setAttestationConfig(uint128 threshold, uint256 fee, uint256 markup) external;
}
