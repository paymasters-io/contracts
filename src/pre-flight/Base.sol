// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";
import {IPaymasterFlow} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymasterFlow.sol";
import {TransactionHelper, Transaction} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";

import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";

/// @title ZkSync Base Paymaster Implementation
abstract contract Base {
    modifier onlyBootloader() {
        require(msg.sender == BOOTLOADER_FORMAL_ADDRESS, "Only bootloader can call this method");
        _;
    }

    event UserOperationValidated(address from, address to, uint256 msgValue, uint256 gasFee);

    /**
     * @notice this method is used to implement gas settlement logic
     * @dev must be overridden
     */
    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable virtual returns (bytes4 magic, bytes memory context);

    /**
     * @notice post Operation. To be called by the bootloader after validation.
     * @dev special function called by the bootloader after user op,
     *  for executing post operation logic like rebates, x chain message etc
     */
    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable virtual {
        // Refunds are not supported yet.
    }

    receive() external payable virtual {}
}
