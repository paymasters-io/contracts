// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./AccessChecker.sol";

/**
 * @title General Paymaster Contract with Access Control
 * @author peter anyaogu
 * @notice this contracts extends the general paymaster with access control rules
 * @dev the struct constructor parameters are to keep code compact.
 */
contract Paymaster is Base, AccessChecker {
    // IPFS metadata hash for offchain identifiers like Logo, Name etc.
    bytes public metadata;

    constructor(
        bytes memory _metadata,
        bool[4] memory rules,
        uint128 maxNonce,
        uint128 ERC20GateValue,
        address ERC20GateContract,
        address NFTGateContract,
        address validationAddress
    ) {
        metadata = _metadata;
        _schema = AccessLibrary.AccessControlSchema(
            maxNonce,
            ERC20GateValue,
            ERC20GateContract,
            NFTGateContract,
            validationAddress,
            new address[](0)
        );
        _rule = AccessLibrary.AccessControlRules(rules[0], rules[1], rules[2], rules[3]);
    }

    /**
     * @notice this method is used to implement gas settlement logic with the general paymaster flow
     * @dev can be extended by Overrides
     * @param _transaction - contains the standard parameters in a tx object for eth_call
     */
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
            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            if (!_satisfy(caller, _transaction.nonce, receiver))
                revert OperationFailed("not eligible");

            TransactionHelper.payToTheBootloader(_transaction);
            emit UserOperationValidated(caller, receiver, _transaction.value, txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }
}
