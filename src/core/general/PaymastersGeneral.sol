// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Core, ECDSA, AccessControlSchema} from "@paymasters-io/core/Core.sol";
import "@paymasters-io/library/Errors.sol";
import "@paymasters-io/interfaces/IRebate.sol";
import "@era/system/contracts/Constants.sol";
import {IPaymasterFlow} from "@era/system/contracts/interfaces/IPaymasterFlow.sol";
import {TransactionHelper, Transaction} from "@era/system/contracts/libraries/TransactionHelper.sol";
import {IPaymaster, ExecutionResult, PAYMASTER_VALIDATION_SUCCESS_MAGIC} from "@era/system/contracts/interfaces/IPaymaster.sol";

contract PaymastersGeneral is IPaymaster, Core {
    bytes4 constant PAYMASTER_VALIDATION_ERROR_MAGIC = 0x043a0804;

    constructor(
        uint256 _maxNonce,
        uint256 erc20GateValue,
        address erc20GateToken,
        address erc721gateToken,
        address _vaa,
        address strictDestination
    ) {
        vaa = _vaa;
        maxNonce = _maxNonce;
        accessControlSchema = AccessControlSchema({
            ERC20GateValue: erc20GateValue,
            ERC20GateContract: erc20GateToken,
            NFTGateContract: erc721gateToken,
            onchainPreviewEnabled: true,
            useStrict: strictDestination != address(0)
        });
        if (strictDestination != address(0)) {
            isDestination[strictDestination] = true;
        }
    }

    modifier onlyBootloader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) revert OnlyBootloader();
        _;
    }

    function getHash(Transaction calldata _transaction, address delegate) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    block.chainid,
                    delegate,
                    address(uint160(_transaction.from)),
                    address(uint160(_transaction.to)),
                    _transaction.nonce,
                    _transaction.gasLimit,
                    _transaction.maxFeePerGas,
                    _transaction.data
                )
            );
    }

    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable onlyBootloader returns (bytes4 magic, bytes memory context) {
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        bool valid = false;

        if (_transaction.paymasterInput.length < 24) revert InvalidPaymasterInput();
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            uint256 providedNonce = _transaction.nonce;
            if (maxNonce != 0 && providedNonce >= maxNonce) revert InvalidNonce(providedNonce);

            address recipient = address(uint160(_transaction.to));
            if (accessControlSchema.useStrict && !isDestination[recipient]) revert AccessDenied();

            address caller = address(uint160(_transaction.from));
            uint256 gasFee = _transaction.gasLimit * _transaction.maxFeePerGas;

            address paymaster = address(bytes20(_transaction.paymasterInput[4:24]));
            require(paymaster != address(0), "invalid paymaster");

            if (
                !(_transaction.paymasterInput.length > 56 &&
                    getHash(_transaction, paymaster) == keccak256(_transaction.paymasterInput[24:56]))
            ) revert InvalidHash();

            if (isDelegator[paymaster]) {
                delegatorsToDebt[paymaster] += gasFee;
                valid = _validateWithDelegation(_transaction.paymasterInput[4:], caller, paymaster);
            } else if (paymaster == address(this)) {
                valid = _validateWithoutDelegation(_transaction.paymasterInput[4:], caller);
            }

            if (valid) {
                context = abi.encode(paymaster, gasFee);
                _payBootloader(gasFee);
            } else {
                // don't revert, just return different magic
                magic = PAYMASTER_VALIDATION_ERROR_MAGIC;
            }
        } else {
            revert UnsupportedPaymasterFlow();
        }
    }

    function _payBootloader(uint256 gasFee) internal onlyBootloader {
        address bootloaderAddr = BOOTLOADER_FORMAL_ADDRESS;
        assembly {
            let success := call(gas(), bootloaderAddr, gasFee, 0, 0, 0, 0)
            if iszero(success) {
                revert(add(0x20, "Not Enough Value For Gas"), 24)
            }
        }
    }

    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable override onlyBootloader {
        // not guaranteed to execute.
        // supports ERC20 rebates by external contract
        if (rebateContract != address(0)) {
            IRebate(rebateContract).rebate(
                address(uint160(_transaction.from)),
                _transaction.value,
                uint8(_txResult),
                _maxRefundedGas,
                _context
            );
        }
    }

    receive() external payable {}
}
