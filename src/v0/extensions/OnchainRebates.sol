// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../BaseGasless.sol";
import "../library/HelperFuncs.sol";

/// @title rebates mechanism for paymasters
/// @author peter anyaogu
/// @notice this plugin adds onchain rebates at POT to paymasters
/// @dev can be used as a base too
contract PayamsterRebatesMiddleware is PaymasterGasless {
    RebateHandler private _rebateParams;
    // tracks the number of times a user has received a rebate
    mapping(address => uint256) private rebateTracker;

    constructor(
        bytes memory bafyhash,
        AccessControlSchema memory schema,
        AccessControlRules memory rules,
        RebateHandler memory rebateParams
    ) PaymasterGasless(bafyhash, schema, rules) {
        _rebateParams = rebateParams;
    }

    /** @notice this is a simple implementation of a rebates mechanism for Gasless Paymasters.
     * feel free to adapt it to your use cases
     * @dev this this method allows for expansion feel free to use oracles, nfts etc.
     * @param _transaction - the tx object passed with eth_call
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

            if (!_satisfy(caller, _transaction.nonce)) revert OperationFailed("not eligible");

            _rebate(_transaction);

            TransactionHelper.payToTheBootloader(_transaction);
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    /// @dev internal function that process on-chain cashback
    /// @param _transaction - the tx object passed with eth_call
    function _rebate(Transaction calldata _transaction) internal {
        address txFrom = address(uint160(_transaction.from));

        bool isEligible = _eligibleForRebate(_transaction.value, txFrom);
        if (isEligible) {
            uint256 amount = (_rebateParams.rebatePercentage * _transaction.value) / 100;
            rebateTracker[txFrom] += 1;
            HelperFuncs.handleTokenTransfer(
                _rebateParams.dispatcher,
                txFrom,
                amount > _rebateParams.maxRebateAmount ? _rebateParams.maxRebateAmount : amount,
                _rebateParams.rebateToken
            );
        }
    }

    /// @dev internal function for checking if user is eligible for rebate
    /// @param txValue - the value passed with the transaction
    /// @param txFrom - the sender of this transaction
    /// @return eligible - true / false
    function _eligibleForRebate(
        uint256 txValue,
        address txFrom
    ) internal view returns (bool eligible) {
        eligible = rebateTracker[txFrom] < _rebateParams.maxNumberOfRebates;

        eligible = eligible && txValue >= _rebateParams.rebateTrigger;
    }
}
