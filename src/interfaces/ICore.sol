// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@paymasters-io/library/AccessControlHelper.sol";

interface ICore {
    function setNodeSigners(address primarySigner, address secondarySigner, uint256 sigCount) external;

    function setDelegator(address delegator, bool value) external;

    function setAccessControlSchema(AccessControlSchema calldata schema) external;

    function setVAA(address _vaa) external;

    function setMaxNonce(uint256 _maxNonce) external;

    function previewAccess(address user) external view returns (bool);

    /// paymasterAndData[4:24] : address(delegator)  || address(this) 20 byte
    /// paymasterAndData[24:56] : bytes32(hash) 32byte
    /// paymasterAndData[56:] : bytes(signatures) >64byte
    function previewValidation(bytes calldata paymasterAndData, address caller) external view returns (bool);

    function withdraw() external;

    function payDebt(address debtor) external payable;
}
