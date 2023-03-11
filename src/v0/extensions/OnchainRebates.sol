// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../BaseGasless.sol";
import "../library/HelperFuncs.sol";
import {RebateHandler} from "../utils/Structs.sol";

// this contracts adds a rebate mechanism to paymasters
// currently inherits from the BaseGasless but can be made to inherit from the BaseERC20 too
// this paymaster contract can serve as a Base too.
contract PayamsterRebatesMiddleware is PaymasterGasless {
    RebateHandler private _rebateParams;
    // tracks the number of times a user has received a rebate
    mapping(address => uint256) private rebateTracker;

    constructor(
        // other params
        bytes memory bafyhash,
        AccessControlSchema memory schema,
        AccessControlRules memory rules
    ) PaymasterGasless(bafyhash, schema, rules) {
        // set other params
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
            address receiver = address(uint160(_transaction.to));

            if (!_satisfy(caller, receiver)) revert OperationFailed("not eligible");

            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            _rebate(_transaction);

            _chargeContractForTx(txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    /// @dev internal function that process on-chain cashback
    /// @param _transaction - the tx object passed with eth_call
    function _rebate(Transaction calldata _transaction) internal {
        // the value passed with the transaction is in the reserved arr
        uint256 transactionValue = _transaction.reserved[1];
        address txFrom = address(uint160(_transaction.from));

        bool isEligible = _eligibleForRebate(transactionValue, txFrom);
        if (isEligible) {
            uint256 amount = (_rebateParams.rebatePercentage * transactionValue) / 100;
            rebateTracker[txFrom] + 1;
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
    function _eligibleForRebate(uint256 txValue, address txFrom)
        internal
        view
        returns (bool eligible)
    {
        eligible = rebateTracker[txFrom] < _rebateParams.maxNumberOfRebates;

        eligible = eligible && txValue >= _rebateParams.rebateTrigger;
    }
}
