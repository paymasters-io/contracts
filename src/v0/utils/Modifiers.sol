// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../interfaces/IAccessChecker.sol";

/// @title paymasters modifiers
/// @author peter anyaogu
/// @notice modifiers for the base paymaster contracts
contract ISmod {
    /// @notice checks the the paymaster address  contains the satisfy method which is used for access control
    /// @param paymasterContract - the address of the paymaster contract
    modifier onlyPaymasters(address paymasterContract) {
        try IAccessChecker(paymasterContract).satisfy(address(this)) returns (bool status) {
            require(status || !status, "unknown error!");
            _;
        } catch {
            revert("contract errored while verifying Ix compatibility!");
        }
    }
}
