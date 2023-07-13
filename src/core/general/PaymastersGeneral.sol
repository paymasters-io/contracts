// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Core, ECDSA, AccessControlSchema} from "@paymasters-io/core/Core.sol";
import "@paymasters-io/library/Errors.sol";
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
        address _vaa
    ) {
        vaa = _vaa;
        maxNonce = _maxNonce;
        accessControlSchema = AccessControlSchema({
            ERC20GateValue: erc20GateValue,
            ERC20GateContract: erc20GateToken,
            NFTGateContract: erc721gateToken,
            onchainPreviewEnabled: true
        });
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

        if (_transaction.paymasterInput.length < 24) revert InvalidPaymasterInput();
        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.general.selector) {
            uint256 providedNonce = _transaction.nonce;
            if (maxNonce != 0 && providedNonce >= maxNonce) revert InvalidNonce(providedNonce);

            address user = address(uint160(_transaction.from));
            uint256 gasFee = _transaction.gasLimit * _transaction.maxFeePerGas;

            if (_transaction.paymasterInput.length > 56) {
                require(
                    getHash(_transaction, address(bytes20(_transaction.paymasterInput[4:24]))) ==
                        keccak256(_transaction.paymasterInput[24:56]),
                    "Invalid hash"
                );
            }

            if (_validateWithDelegation(_transaction.paymasterInput, user)) {
                (bool success, ) = payable(BOOTLOADER_FORMAL_ADDRESS).call{value: gasFee}("");
                if (!success) revert NotEnoughValueForGas();
            } else {
                // don't revert, just return a different magic number
                magic = PAYMASTER_VALIDATION_ERROR_MAGIC;
            }
        } else {
            revert UnsupportedPaymasterFlow();
        }
    }

    function postTransaction(
        bytes calldata _context,
        Transaction calldata _transaction,
        bytes32,
        bytes32,
        ExecutionResult _txResult,
        uint256 _maxRefundedGas
    ) external payable override onlyBootloader {}

    receive() external payable {}
}
