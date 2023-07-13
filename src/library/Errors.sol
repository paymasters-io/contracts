// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error InvalidSignatureLength();
error InvalidConfig();
error UnAuthorized();
error FailedToValidateOp();
error FailedToValidateOpDelegation();
error InvalidNonce(uint256 nonce);
error OnlyBootloader();
error InvalidPaymasterInput();
error UnsupportedPaymasterFlow();
error NotEnoughValueForGas();
error OperationFailed();
error PriceNotAvailable();
