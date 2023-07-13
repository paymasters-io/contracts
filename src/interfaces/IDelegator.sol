// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDelegator {
    /// paymasterAndData[4:24] : address(delegator)  || address(this) 20 byte
    /// paymasterAndData[24:56] : bytes32(hash) 32byte
    /// paymasterAndData[56:] : bytes(signatures) >64byte
    function previewValidation(bytes calldata paymasterAndData, address caller) external view returns (bool);
}
