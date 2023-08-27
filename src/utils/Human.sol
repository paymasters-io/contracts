// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/interfaces/IWorldID.sol";
import "@paymasters-io/library/ByteHash.sol";

contract Human {
    using ByteHasher for bytes;

    /// @dev The address of the World ID Router contract that will be used for verifying proofs
    IWorldID internal immutable worldId;

    /// @dev The keccak256 hash of the externalNullifier (unique identifier of the action performed), combination of appId and action
    uint256 internal immutable externalNullifierHash;

    /// @dev The World ID group ID (1 for Orb-verified, 0 for phone verified)
    uint256 internal immutable groupId = 1;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) internal nullifierHashes;

    /// @param _worldId The WorldID instance that will verify the proofs
    /// @param _appId The World ID app ID
    /// @param _action The World ID action ID
    constructor(IWorldID _worldId, string memory _appId, string memory _action) {
        worldId = _worldId;
        externalNullifierHash = abi.encodePacked(abi.encodePacked(_appId).hashToField(), _action).hashToField();
    }

    /// @param signal An arbitrary input from the user that cannot be tampered with. In this case, it is the user's wallet address.
    /// @param root The root (returned by the IDKit widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the IDKit widget).
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the IDKit widget).
    function isHuman(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) public view returns (bool human) {
        human = false;
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifierHash,
            proof
        );
        human = true;
    }

    function _afterValidation(uint256 nullifierHash) internal virtual {
        nullifierHashes[nullifierHash] = true;
    }
}
