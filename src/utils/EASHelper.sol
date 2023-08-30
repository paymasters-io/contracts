// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@eas/contracts/IEAS.sol";
import "@paymasters-io/interfaces/IEASHelper.sol";

/// modular contracts enabled by EAS.
/// only one instance per chain.
contract EASHelper is SchemaResolver, Ownable, IEASHelper {
    bytes32 immutable _schemaId;

    uint256 _threshold;
    uint256 _registrationFee;
    uint256 _attestersMarkup;

    mapping(address => bool) _validAttesters;
    mapping(address => Attestations) _attestations;
    mapping(address => mapping(address => bool)) _attested;

    constructor(
        IEAS eas,
        ISchemaRegistry schemaReg,
        address _owner
    ) SchemaResolver(eas) Ownable(_owner) {
        string
            memory schema = "bytes32 name, address moduleAddress, address manager, bool verified, bool safe";
        _schemaId = schemaReg.register(schema, this, true);
    }

    function addAttester(address attester) external onlyOwner {
        _validAttesters[attester] = true;
    }

    function removeAttester(address attester) external onlyOwner {
        _validAttesters[attester] = false;
    }

    function addAttesters(address[] calldata attesters) external onlyOwner {
        for (uint256 i = 0; i < attesters.length; i++) {
            _validAttesters[attesters[i]] = true;
        }
    }

    function removeAttesters(address[] calldata attesters) external onlyOwner {
        for (uint256 i = 0; i < attesters.length; i++) {
            _validAttesters[attesters[i]] = false;
        }
    }

    function setAttestationConfig(
        uint128 threshold,
        uint256 fee,
        uint256 markup
    ) external onlyOwner {
        _threshold = threshold;
        _registrationFee = fee;
        _attestersMarkup = markup;
    }

    function _attestEAS(
        address name,
        address moduleAddress,
        address manager,
        bool verified,
        bool safe
    ) internal {
        AttestationRequestData memory easRequestData = AttestationRequestData(
            address(this),
            type(uint64).max,
            true,
            bytes32(0),
            abi.encode(name, moduleAddress, manager, verified, safe),
            msg.value
        );
        AttestationRequest memory request = AttestationRequest(_schemaId, easRequestData);
        _eas.attest(request);
    }

    function _revokeEAS(bytes32 uuid) internal {
        RevocationRequest memory request = RevocationRequest(
            _schemaId,
            RevocationRequestData(uuid, msg.value)
        );
        _eas.revoke(request);
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        if (!_validAttesters[attestation.attester]) return false;
        (, address module, , bool verified, bool safe) = abi.decode(
            attestation.data,
            (bytes32, address, address, bool, bool)
        );
        Attestations memory atts = _attestations[module];
        bool attested = _attested[module][attestation.attester];
        uint256 threshold = _threshold;
        if (attested) return false;
        if (!verified || !safe || module == address(0)) return false;
        if (atts.attestationStatus == AttestationStatus.Rejected) return false;
        if (atts.attestationStatus == AttestationStatus.None) {
            _attestations[module].attestationStatus = AttestationStatus.Pending;
        }
        _attestations[module].attestationCount++;
        if (atts.attestationCount <= threshold) {
            _attested[module][attestation.attester] = true;
        }
        if (
            atts.attestationCount >= threshold &&
            atts.attestationStatus == AttestationStatus.Pending
        ) {
            _attestations[module].attestationStatus = AttestationStatus.Approved;
        }
        return true;
    }

    function onRevoke(
        Attestation calldata attestation,
        uint256 /*value*/
    ) internal override returns (bool) {
        if (!_validAttesters[attestation.attester]) return false;
        (, address module, , , ) = abi.decode(
            attestation.data,
            (bytes32, address, address, bool, bool)
        );
        if (_attestations[module].attestationStatus != AttestationStatus.Rejected) {
            _attestations[module].attestationStatus = AttestationStatus.Rejected;
        }
        return true;
    }
}
