// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../BaseGasless.sol";
import "../library/HelperFuncs.sol";

/// @title triggered paymasters
/// @author peter anyaogu
/// @notice plugin that enables gas offset when the transaction meets a certain criteria
/// @dev inherits from BaseGasless but can inherit BaseERC20
contract PaymasterTriggeredGasless is PaymasterGasless {
    constructor(
        bytes memory bafyhash,
        AccessControlSchema memory schema,
        AccessControlRules memory rules,
        TriggerRules memory tRules
    ) PaymasterGasless(bafyhash, schema, rules) {
        _tRules = tRules;
    }

    /// @notice this method is used to implement gas settlement logic with the general paymaster flow
    /// @dev can be extended by Overrides
    /// @param _transaction - contains the standard parameters in a tx object for eth_call
    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override onlyBootloader returns (bytes4 magic, bytes memory context) {
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        if (_transaction.paymasterInput.length < 4) revert OperationFailed("input < 4 bytes");
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            address caller = address(uint160(_transaction.from));
            address receiver = address(uint160(_transaction.to));

            if (
                !_satisfy(caller, _transaction.nonce) ||
                !previewTrigger(receiver, _transaction.value, _transaction.data)
            ) revert OperationFailed("not eligible");

            TransactionHelper.payToTheBootloader(_transaction);
        } else {
            revert("Unsupported paymaster flow");
        }
    }
}
