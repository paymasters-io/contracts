// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Structs.sol";
import "../library/AccessControl.sol";

contract AccessChecker {
    ApprovalBasedFlow internal _flow;
    AccessControlSchema internal _schema;
    AccessControlRules internal _rules;

    error OperationFailed(bytes reason);

    /// @notice allows paymaster to check caller eligibility in using this contract
    /// @param addressToCheck - to address to satisfy
    /// @return - true / false
    function satisfy(address addressToCheck) external payable returns (bool) {
        return _satisfy(addressToCheck, address(0));
    }

    /// @dev internal function for access control
    /// @param addressToCheck - to address to satisfy
    /// @param txTo - the destination contract for the accompanying transaction
    /// @return truthy - true / false depending if the user passed all provided checks
    function _satisfy(address addressToCheck, address txTo) internal virtual returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.
        if (_rules.useMaxNonce) {
            truthy = truthy && AccessControl.useMaxNonce(_schema.maxNonce, addressToCheck);
        }

        if (_rules.useERC20Gate) {
            truthy =
                truthy &&
                AccessControl.useERC20Gate(
                    _schema.ERC20GateContract,
                    _schema.ERC20GateValue,
                    addressToCheck
                );
        }

        if (_rules.useNFTGate) {
            truthy = truthy && AccessControl.useNFTGate(_schema.NFTGateContract, addressToCheck);
        }

        if (_rules.useStrictDestination && txTo != address(0)) {
            truthy = truthy && AccessControl.useStrictDestination(txTo, _schema.strictDestinations);
        }
    }
}
