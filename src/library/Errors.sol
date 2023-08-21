// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error InvalidSignatureLength();
error InvalidConfig();
error UnAuthorized();
error FailedToValidateOp();
error InvalidHash();
error InvalidNonce(uint256 nonce);
error OnlyBootloader();
error InvalidPaymasterInput();
error UnsupportedPaymasterFlow();
error AccessDenied();
error TokenNotSupported(address token);
error OperationFailed();
error PriceNotAvailable();
