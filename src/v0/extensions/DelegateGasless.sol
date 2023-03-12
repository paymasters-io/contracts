// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../Base.sol";
import "../library/AccessControl.sol";
import "../utils/Structs.sol";
import "../utils/AccessChecker.sol";

// this contract delegates bootloader calls from the current contract to another contract
// only if the paymaster does not have enough eth balance.
// it specifies a sister paymaster which must be an IPaymasterDelegationProxy too
// the sister paymaster can be updated
// NB: this contract makes paymasters themselves proxies as well as implementations
// if a vulnerability is detected. the paymaster can continue working by delegating all calls to another paymaster.
// adapt it to approval based paymaster if you wish
// also - selector clashes may happen so make sure that sister contract is protected and trusted.
contract PaymasterGaslessDelegationProxy is Base, AccessChecker {
    bytes public metadata;
    address public sister;
    address private immutable _self = address(this);

    constructor(
        bytes memory bafyhash,
        AccessControlSchema memory schema,
        AccessControlRules memory rules,
        address _sister
    ) {
        metadata = bafyhash;
        _schema = schema;
        _rules = rules;
        sister = _sister;
    }

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

            if (!_satisfy(caller, receiver)) revert OperationFailed("not eligible");

            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            _delegate(txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    //? audit and test required!
    // according to delegateCall [address(this), msg.sender, msg.value]
    // will remain the same throughout the context of the implementation contract
    // so msg.sender will still be the bootloader
    // this may only be called in the implementation
    // unless zkSync Bootloader becomes malicious.
    function delegate(uint256 txCost) external onlyBootloader {
        //! payable(address).call{} ? will this happen in the context of:
        //! execution contract or implementation contract?
        _chargeContractForTx(txCost);
    }

    /// @dev internal function that performs the actual delegation
    /// @param txCost - the actual cost of the transaction
    function _delegate(uint256 txCost) internal {
        if (_self.balance > txCost) {
            _chargeContractForTx(txCost);
        } else {
            (, bytes memory data) = sister.delegatecall(
                abi.encodeWithSelector(this.delegate.selector, txCost)
            );
        }
    }

    function updateSister(address newSister) public {
        if (msg.sender != _schema.validationAddress) revert OperationFailed("unauthorized");
        sister = newSister;
    }
}
