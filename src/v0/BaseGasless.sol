// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./library/AccessControl.sol";
import "./utils/AccessChecker.sol";
import "./utils/Structs.sol";

/// @title General Paymaster Contract with Access Control
/// @author peter anyaogu
/// @notice this contracts extends the general paymaster with access control rules
/// @dev the struct constructor parameters are to keep code compact.
contract PaymasterGasless is Base, AccessChecker {
    // IPFS metadata hash for offchain identifiers like Logo, Name etc.
    bytes public metadata;

    //structs should not be passed to constructor.
    constructor(
        bytes memory bafyhash,
        AccessControlSchema memory schema,
        AccessControlRules memory rules
    ) {
        metadata = bafyhash;
        _schema = schema;
        _rules = rules;
    }

    /// @notice this method is used to implement gas settlement logic with the general paymaster flow
    /// @dev can be extended by Overrides
    /// @param _transaction - contains the standard parameters in a tx object for eth_call
    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    )
        external
        payable
        virtual
        override
        onlyBootloader
        returns (bytes4 magic, bytes memory context)
    {
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        if (_transaction.paymasterInput.length < 4) revert OperationFailed("input < 4 bytes");
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            address caller = address(uint160(_transaction.from));
            address receiver = address(uint160(_transaction.to));

            if (!_satisfy(caller, receiver)) revert OperationFailed("not eligible");

            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            _chargeContractForTx(txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }
}
