// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Base.sol";
import "./AccessChecker.sol";
import "./library/HelperFuncs.sol";
import "./interfaces/IOracle.sol";

/**
 * @title Approval Based Paymaster Contract with Access Control
 * @author peter anyaogu
 * @notice this contracts extends the approval based paymaster with access control rules
 * @dev the struct constructor parameters are to keep code compact.
 */
contract Paymaster is Base, AccessChecker {
    // IPFS metadata hash for offchain identifiers like Logo, Name etc.
    bytes public metadata;
    IOracle private _oracle;

    AccessLibrary.ApprovalBasedFlow private _flow;

    constructor(
        bytes memory bafyhash,
        bool[4] memory rules,
        uint128 maxNonce,
        uint128 ERC20GateValue,
        address ERC20GateContract,
        address NFTGateContract,
        address validationAddress
    ) {
        metadata = bafyhash;
        _schema = AccessLibrary.AccessControlSchema(
            maxNonce,
            ERC20GateValue,
            ERC20GateContract,
            NFTGateContract,
            validationAddress,
            new address[](0)
        );
        _rule = AccessLibrary.AccessControlRules(rules[0], rules[1], rules[2], rules[3]);
    }

    /**
     * @notice this method is used to implement gas settlement logic with approval-based flow
     * @dev can be extended by Overrides
     * @param _transaction - - contains the standard parameters in a tx object for eth_call
     * @return magic - paymaster validation was successful
     * @return context
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
        if (paymasterInputSelector == IPaymasterFlow.approvalBased.selector) {
            (address token, uint256 minAllowance, ) = abi.decode(
                _transaction.paymasterInput[4:],
                (address, uint256, bytes)
            );
            address caller = address(uint160(_transaction.from));
            address receiver = address(uint160(_transaction.to));
            uint256 txCost = _transaction.gasLimit * _transaction.maxFeePerGas;

            if (
                !_satisfy(caller, _transaction.nonce, receiver) ||
                token != address(_flow.l2FeeToken) ||
                minAllowance < _flow.l2FeeAmount
            ) revert OperationFailed("verification failed");

            HelperFuncs.handleTokenTransfer(
                caller,
                _schema.validationAddress,
                _flow.useOracleQuotes ? _processOracleRequest(txCost) : _flow.l2FeeAmount,
                _flow.l2FeeToken
            );

            TransactionHelper.payToTheBootloader(_transaction);
            emit UserOperationValidated(caller, receiver, _transaction.value, txCost);
        } else {
            revert("Unsupported paymaster flow");
        }
    }

    /**
     * @dev internal function that handles chainlink priceFeed requests
     * @param txCost -  the cost of this tx in wei
     * @return - the cost of this tx in ERC20 denominated in wei
     */
    function _processOracleRequest(uint256 txCost) internal view returns (uint256) {
        int256 fee = _oracle.getDerivedPrice(_flow.priceFeed, int256(txCost));
        return uint256(fee);
    }

    /**
     * @dev Updates the fee model. if not updated. txs will fail
     * @param l2FeeAmount static amount-to-gas charged per tx
     * @param useOracleQuotes activate the use of price oracle for gas fee quotes
     * @param priceFeed erc20 token priceFeed on chainlink
     * @param l2FeeToken fee payment erc20 token contract address
     */
    function setFeeModel(
        uint256 l2FeeAmount,
        bool useOracleQuotes,
        address priceFeed,
        address l2FeeToken
    ) public onlyValidator {
        _flow = AccessLibrary.ApprovalBasedFlow(
            l2FeeAmount,
            useOracleQuotes,
            priceFeed,
            IERC20(l2FeeToken)
        );
    }

    /**
     * @notice update the price oracle contract
     * @param oracleAddress the address of the new oracle
     */
    function setOracle(address oracleAddress) public onlyValidator {
        _oracle = IOracle(oracleAddress);
    }
}
