// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAccessChecker {
    /**
     * sets a new entry for allowed txTo
     * strictDestinations enforces the paymaster to work only with specified contracts.
     * if the current txTo in the tx calldata is allowed.
     * @param allowedTxTo - a new allowed transaction destination
     */
    function addDestination(address allowedTxTo) external;

    /**
     * removes an entry for allowed txTo.
     * @param index - location of data to be popped off
     */
    function removeDestination(uint256 index) external;

    /**
     * changes an access control validation logic parameter.
     * @param schema - string representation of the schema name
     * @param data - value to be set as the schema default.
     */
    function updateSchema(bytes calldata schema, bytes calldata data) external;

    /**
     * changes an access control rule. enabling or disabling it.
     * @param rule - string representation of the rule name
     * @param value - rule value to be set
     */
    function updateRules(bytes calldata rule, bool value) external;

    /// @notice allows paymaster to check caller eligibility in using this contract
    /// @param addressToCheck - to address to satisfy
    /// @return - true / false
    function previewSatisfy(address addressToCheck) external payable returns (bool);
}
