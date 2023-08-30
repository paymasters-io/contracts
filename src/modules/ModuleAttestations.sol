// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";
import {IEAS} from "@eas/contracts/IEAS.sol";
import "@paymasters-io/interfaces/IModuleAttestations.sol";
import {FailedToWithdrawEth} from "@paymasters-io/interfaces/IModule.sol";

// "bytes32 name, address moduleAddress, address manager, bool verified, bool safe"

/// modular contracts enabled by EAS.
/// only one instance per chain.
contract ModuleAttestations is SchemaResolver, Ownable, IModuleAttestations {
    bytes32 immutable _schemaId;

    mapping(address => bool) _validAttesters; // attester => valid
    mapping(address => Attestations) _attestations; // module => attestation
    mapping(address => mapping(address => bool)) _attested; // attester => module => attested

    uint64 constant UNLOCK_DELAY = 1 days;
    uint64 _attestersMarkup = 1.5e5; // 15%
    uint8 _threshold = 3; // 3 attesters
    uint256 _registrationFee = 2.5e16; // 0.025 ether

    constructor(
        IEAS eas,
        ISchemaRegistry schemaReg,
        string memory schema,
        address _owner
    ) SchemaResolver(eas) Ownable(_owner) {
        _schemaId = schemaReg.register(schema, this, true);
    }

    modifier onlyValidAttester(address attester) {
        require(_validAttesters[attester], "Invalid attester");
        _;
    }

    function applyForAttestations() external payable returns (bool success) {
        if (msg.value < _registrationFee) revert InsufficientValue();
        if (_attestations[msg.sender].attestationCount > 0) revert AlreadyAttested();
        _attestations[msg.sender].fee = msg.value;
        success = true;
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

    function setAttestationConfig(uint8 threshold, uint64 markup, uint256 fee) external onlyOwner {
        _threshold = threshold;
        _registrationFee = fee;
        _attestersMarkup = markup;
    }

    function attestationResolved(address module) external view returns (bool) {
        if (module == address(0)) return false;
        Attestations memory atts = _attestations[module];
        return _onlyUnlocked(atts);
    }

    function getAttestationFee() external view returns (uint256) {
        return _registrationFee;
    }

    function withdrawFeeOnSuccess() external {
        Attestations memory atts = _attestations[msg.sender];
        if (!_onlyUnlocked(atts)) revert NotUnlocked();
        uint256 totalCut = (atts.uids.length * (atts.fee * _attestersMarkup)) / 1e6;
        uint256 fee = atts.fee - totalCut;
        (bool success, ) = msg.sender.call{value: fee}("");
        if (!success) revert FailedToWithdrawEth(msg.sender, fee);
    }

    function claimAttestersCut(address module, bytes32 uid) external onlyValidAttester(msg.sender) {
        uint256 cut = _claimCut(module, uid);
        (bool success, ) = msg.sender.call{value: cut}("");
        if (!success) revert FailedToWithdrawEth(msg.sender, cut);
    }

    function multiClaimAttestersCut(
        MultiAttestClaim[] calldata claims
    ) external onlyValidAttester(msg.sender) {
        uint256 cut = 0;
        for (uint256 i = 0; i < claims.length; i++) {
            cut += _claimCut(claims[i].module, claims[i].uid);
        }
        (bool success, ) = msg.sender.call{value: cut}("");
        if (!success) revert FailedToWithdrawEth(msg.sender, cut);
    }

    function attestEAS(
        address name,
        address moduleAddress,
        address manager,
        bool verified,
        bool safe
    ) external payable {
        AttestationRequestData memory easRequestData = AttestationRequestData(
            address(this),
            type(uint64).max,
            true,
            bytes32(0),
            abi.encode(name, moduleAddress, manager, verified, safe),
            msg.value
        );
        AttestationRequest memory request = AttestationRequest(_schemaId, easRequestData);
        bytes32 uid = _eas.attest(request);
        require(uid != bytes32(0), "Failed to attest");
    }

    function revokeEAS(bytes32 uuid) external payable {
        RevocationRequest memory request = RevocationRequest(
            _schemaId,
            RevocationRequestData(uuid, msg.value)
        );
        _eas.revoke(request);
    }

    function _claimCut(address module, bytes32 uid) internal returns (uint256 cut) {
        Attestations memory atts = _attestations[module];
        if (!_onlyUnlocked(atts)) revert NotUnlocked();
        int256 uidIndex = _getUIDIndex(atts.uids, uid);
        if (uidIndex < 0) revert AccessDenied();
        _deleteUIDByIndex(uint256(uidIndex), module, atts.uids[atts.uids.length - 1]);
        cut = (atts.fee * _attestersMarkup) / 1e6;

        Attestation memory attestation = _eas.getAttestation(uid);
        if (attestation.attester != msg.sender) revert NotTheAttester(msg.sender, attestation.uid);
    }

    function _getUIDIndex(bytes32[] memory uids, bytes32 uid) internal pure returns (int256) {
        for (uint256 i = 0; i < uids.length; i++) {
            if (uids[i] == uid) {
                return int256(i);
            }
        }
        return -1;
    }

    function _deleteUIDByIndex(uint256 index, address module, bytes32 uid) internal {
        _attestations[module].uids[index] = uid;
        _attestations[module].uids.pop();
    }

    function _onlyUnlocked(Attestations memory atts) internal view returns (bool) {
        bool unlocked = atts.attestationStatus == AttestationStatus.Approved &&
            block.timestamp - atts.timestamp > UNLOCK_DELAY;

        return unlocked;
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
        bool attested = _attested[attestation.attester][module];
        uint8 threshold = _threshold;
        if (attested) return false;
        if (!verified || !safe || module == address(0)) return false;
        if (atts.attestationStatus == AttestationStatus.Rejected) return false;
        if (atts.attestationStatus == AttestationStatus.None) {
            _attestations[module].attestationStatus = AttestationStatus.Pending;
        }
        _attestations[module].attestationCount++;
        if (atts.attestationCount <= threshold) {
            _attested[attestation.attester][module] = true;
        }
        if (
            atts.attestationCount >= threshold &&
            atts.attestationStatus == AttestationStatus.Pending
        ) {
            _attestations[module].attestationStatus = AttestationStatus.Approved;
            _attestations[module].timestamp = uint64(block.timestamp);
        }
        _attestations[module].uids.push(attestation.uid);
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
        _attestations[module].attestationCount--;
        return true;
    }
}
