// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Structs.sol";
import "../library/AccessControl.sol";
import "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";

contract AccessChecker {
    using AccessControl for TriggerSchema;

    ApprovalBasedFlow internal _flow;
    AccessControlSchema internal _schema;
    AccessControlRules internal _rules;
    TriggerSchema internal _tSchema;
    TriggerRules internal _tRules;

    error OperationFailed(bytes reason);

    modifier onlyValidator() {
        if (msg.sender != _schema.validationAddress) revert OperationFailed("unauthorized");
        _;
    }

    /// @notice allows paymaster to check caller eligibility in using this contract
    /// @param addressToCheck - to address to satisfy
    /// @return - true / false
    function previewSatisfy(address addressToCheck) external payable virtual returns (bool) {
        bytes memory payload = abi.encodeWithSignature("getMinNonce(address)", addressToCheck);
        return
            _satisfy(
                addressToCheck,
                AccessControl.externalCall(payload, address(NONCE_HOLDER_SYSTEM_CONTRACT))
            );
    }

    /// @notice simulates the outcome of a transaction validation
    /// checks if the transaction can trigger gas offsets
    /// @param txTo - the destination contract
    /// @param txValue - the value to be passed with a transaction
    /// @param msgData - the msg.data (selectors and input params)
    /// @return - true/false
    function previewTrigger(
        address txTo,
        uint256 txValue,
        bytes memory msgData
    ) public payable virtual returns (bool) {
        if (_rules.useTriggers) {
            return _trigger(txTo, txValue, msgData);
        }
        return true;
    }

    /// @dev allows a validationAddress to update the trigger schema
    /// @param selector selector to check
    /// @param calldataParam the params of the calldata input
    function addTriggerSelector(
        bytes4 selector,
        uint256[2] memory calldataParam
    ) public onlyValidator {
        _tSchema.calldataSelectors.push(selector);
        _tSchema.calldataMinParams[selector] = calldataParam;
    }

    //### VALIDATOR ONLY FUNCTIONS ###

    function removeTriggerSelector(uint256 index) public onlyValidator {
        bytes4 selector = _tSchema.calldataSelectors[index];
        delete _tSchema.calldataMinParams[selector];
        delete _tSchema.calldataSelectors[index];
    }

    function addDestination(address strictDestination) public onlyValidator {
        _tSchema.strictDestinations.push(strictDestination);
    }

    function removeDestination(uint256 index) public onlyValidator {
        delete _tSchema.strictDestinations[index];
    }

    function setMinMsgValue(uint256 minMsgValue) public onlyValidator {
        _tSchema.minMsgValue = minMsgValue;
    }

    function updateMaxNonce(uint256 value) public onlyValidator {
        _schema.maxNonce = value;
    }

    function updateERC20Gate(
        uint256 ERC20GateValue,
        address ERC20GateContract
    ) public onlyValidator {
        _schema.ERC20GateValue = ERC20GateValue;
        _schema.ERC20GateContract = ERC20GateContract;
    }

    function updateNFTGate(address NFTGateContract) public onlyValidator {
        _schema.NFTGateContract = NFTGateContract;
    }

    function updateApprovalBasedToken(uint256 l2FeeAmount, IERC20 l2FeeToken) public onlyValidator {
        _flow.l2FeeAmount = l2FeeAmount;
        _flow.l2FeeToken = l2FeeToken;
    }

    /// @dev internal function for access control
    /// @param addressToCheck - to address to satisfy
    /// @return truthy - true / false depending if the user passed all provided checks
    function _satisfy(
        address addressToCheck,
        uint256 providedNonce
    ) internal virtual returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.
        if (_rules.useMaxNonce) {
            truthy = truthy && AccessControl.useMaxNonce(_schema.maxNonce, providedNonce);
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
    }

    /// @dev internal function to perform transaction validation
    /// @param txTo - the destination contract
    /// @param txValue - the value to be passed with a transaction
    /// @param msgData - the msg.data (selectors and input params)
    /// @return triggered - true/false
    function _trigger(
        address txTo,
        uint256 txValue,
        bytes memory msgData
    ) internal virtual returns (bool triggered) {
        triggered = true; // true & true = true, true & false = false, false & false = false.
        if (_tRules.useStrictDestination) {
            triggered = triggered && _tSchema.useStrictDestination(txTo);
        }
        if (_tRules.useMsgValue) {
            triggered = triggered && _tSchema.useMinValue(txValue);
        }

        if (_tRules.useSelector && _tSchema.calldataSelectors.length > 0) {
            triggered = triggered && _tSchema.validSelector(msgData);
        }

        if (_tRules.useSelectorParams && _tSchema.calldataSelectors.length > 0) {
            triggered = triggered && _tSchema.validSelectorParams(msgData);
        }
    }
}
