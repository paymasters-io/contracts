// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../BaseERC20.sol";
import "../../chainlink/PriceFeedConsumer.sol";

// chainlink compatible paymaster
// @notice - chainlink is currently not in zksync
// this contract will not work until chainlink becomes available in zksync
// you can adapt this to any oracle as you wish
contract PaymasterOracleEnabled is PaymasterERC20 {
    PriceFeedConsumer private _oracle;

    constructor(
        bytes memory bafyhash,
        address oracle,
        AccessControlSchema memory schema,
        AccessControlRules memory rules,
        ApprovalBasedFlow memory feeModel
    ) PaymasterERC20(bafyhash, schema, rules, feeModel) {
        _oracle = PriceFeedConsumer(oracle);
    }

    function validateAndPayForPaymasterTransaction(
        bytes32,
        bytes32,
        Transaction calldata _transaction
    ) external payable override onlyBootloader returns (bytes4 magic, bytes memory context) {
        magic = PAYMASTER_VALIDATION_SUCCESS_MAGIC;
        if (_transaction.paymasterInput.length < 4) revert OperationFailed("input < 4 bytes");

        bytes4 paymasterInputSelector = bytes4(_transaction.paymasterInput[0:4]);
        if (paymasterInputSelector == IPaymasterFlow.approvalBased.selector) {
            (address token, uint256 minAllowance, ) = abi.decode(
                _transaction.paymasterInput[4:],
                (address, uint256, bytes)
            );
            address caller = address(uint160(_transaction.from));
            address receiver = address(uint160(_transaction.to));

            if (
                !_satisfy(caller, receiver) ||
                token != address(_flow.l2FeeToken) ||
                minAllowance < _flow.l2FeeAmount
            ) revert OperationFailed("verification failed");

            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            HelperFuncs.handleTokenTransfer(
                caller,
                address(0),
                _flow.useOracleQuotes ? _processOracleRequest(txCost) : _flow.l2FeeAmount,
                _flow.l2FeeToken
            );
            _chargeContractForTx(txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    /// @dev internal function that handles chainlink priceFeed requests
    /// @param txCost -  the cost of this tx in wei
    /// @return - the cost of this tx in ERC20 denominated in wei
    function _processOracleRequest(uint256 txCost) internal view returns (uint256) {
        int256 fee = _oracle.getDerivedPrice(
            _flow.priceFeed,
            // you can set own pricefeed
            _oracle.getQuotePriceFeed(),
            int256(txCost)
        );
        return uint256(fee);
    }

    /// @notice asynchronous update of the price oracle contract
    /// @param oracleAddress the address of the new oracle
    function setOracle(address oracleAddress) public {
        if (msg.sender != _schema.validationAddress) revert OperationFailed("unauthorized");
        _oracle = PriceFeedConsumer(oracleAddress);
    }
}
