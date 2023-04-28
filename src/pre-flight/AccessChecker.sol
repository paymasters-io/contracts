// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./library/AccessLibrary.sol";
import "./library/AccessControl.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";

contract AccessChecker {
    using AccessControl for AccessLibrary.AccessControlSchema;
    using AccessLibrary for AccessLibrary.AccessControlSchema;
    using AccessLibrary for AccessLibrary.AccessControlRules;

    AccessLibrary.AccessControlSchema internal _schema;
    AccessLibrary.AccessControlRules internal _rule;

    /**
     * sets a new entry for allowed txTo
     * strictDestinations enforces the paymaster to work only with specified contracts.
     * if the current txTo in the tx calldata is allowed.
     * @param allowedTxTo - a new allowed transaction destination
     */
    function addDestination(address allowedTxTo) public onlyValidator {
        _schema.strictDestinations.push(allowedTxTo);
    }

    /**
     * removes an entry for allowed txTo.
     * @param index - location of data to be popped off
     */
    function removeDestination(uint256 index) public onlyValidator {
        // order does not matter.
        delete _schema.strictDestinations[index];
    }

    /**
     * changes an access control validation logic parameter.
     * @param schema - string representation of the schema name
     * @param data - value to be set as the schema default.
     */
    function updateSchema(bytes calldata schema, bytes calldata data) public onlyValidator {
        _schema.updateSchema(schema, data);
    }

    /**
     * changes an access control rule. enabling or disabling it.
     * @param rule - string representation of the rule name
     * @param value - rule value to be set
     */
    function updateRules(bytes calldata rule, bool value) public onlyValidator {
        _rule.updateRules(rule, value);
    }

    /**
     * @notice allows paymaster to check caller eligibility in using this contract
     * @param addressToCheck - to address to satisfy
     * @return - true / false
     */
    function previewSatisfy(address addressToCheck) external payable virtual returns (bool) {
        bytes memory payload = abi.encodeWithSignature("getMinNonce(address)", addressToCheck);
        return
            _satisfy(
                addressToCheck,
                AccessControl.externalCall(payload, address(NONCE_HOLDER_SYSTEM_CONTRACT)),
                address(0)
            );
    }

    /**
     * @dev internal function for access control
     * @param addressToCheck - to address to satisfy
     * @param providedNonce - true / false depending if the user passed all provided checks
     * @param txTo -the transaction to as referenced in the calldata
     * @return truthy - true / false depending if the user passed all provided checks
     */
    function _satisfy(
        address addressToCheck,
        uint256 providedNonce,
        address txTo
    ) internal virtual returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.
        if (_rule.useMaxNonce) {
            truthy = truthy && AccessControl.useMaxNonce(_schema.maxNonce, providedNonce);
        }

        if (_rule.useStrictDestination && txTo != address(0)) {
            truthy = truthy && _schema.useStrictDestination(txTo);
        }

        if (_rule.useNFTGate) {
            truthy = truthy && AccessControl.useNFTGate(_schema.NFTGateContract, addressToCheck);
        }

        if (_rule.useERC20Gate) {
            truthy =
                truthy &&
                AccessControl.useERC20Gate(
                    _schema.ERC20GateContract,
                    _schema.ERC20GateValue,
                    addressToCheck
                );
        }
    }

    error OperationFailed(bytes reason);

    modifier onlyValidator() {
        if (msg.sender != _schema.validationAddress) revert OperationFailed("unauthorized");
        _;
    }
}
