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
        bytes calldata msgData
    ) public payable virtual returns (bool) {
        if (_rules.useTriggers) {
            return _trigger(txTo, txValue, msgData);
        }
        return true;
    }

    //### VALIDATOR ONLY FUNCTIONS ###

    /// @dev allows a validationAddress to update the trigger schema
    /// @param selector selector to check
    /// @param calldataParam the params of the calldata input
    function addTriggerSelector(bytes4 selector, uint256[2] memory calldataParam)
        public
        onlyValidator
    {
        _tSchema.calldataSelectors.push(selector);
        _tSchema.calldataMinParams[selector] = calldataParam;
    }

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

    function compare(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    //###### UPDATES MULTICALL ########

    function updateSchema(bytes memory schema, bytes calldata data) public onlyValidator {
        if (compare(schema, "maxNonce")) {
            _schema.maxNonce = abi.decode(data, (uint256));
        }
        if (compare(schema, "ERC20GateValue")) {
            _schema.ERC20GateValue = abi.decode(data, (uint256));
        }
        if (compare(schema, "ERC20GateContract")) {
            _schema.ERC20GateContract = abi.decode(data, (address));
        }
        if (compare(schema, "NFTGateContract")) {
            _schema.NFTGateContract = abi.decode(data, (address));
        }
        if (compare(schema, "l2FeeAmount")) {
            _flow.l2FeeAmount = abi.decode(data, (uint256));
        }
        if (compare(schema, "l2FeeToken")) {
            _flow.l2FeeToken = IERC20(abi.decode(data, (address)));
        }
        if (compare(schema, "minMsgValue")) {
            _tSchema.minMsgValue = abi.decode(data, (uint256));
        }
    }

    //##### TOGGLES MULTICALL ######

    function toggleRule(bytes memory rule) public onlyValidator {
        if (compare(rule, "useMaxNonce")) {
            _rules.useMaxNonce = _rules.useMaxNonce ? false : true;
        }
        if (compare(rule, "useERC20Gate")) {
            _rules.useERC20Gate = _rules.useERC20Gate ? false : true;
        }
        if (compare(rule, "useNFTGate")) {
            _rules.useNFTGate = _rules.useNFTGate ? false : true;
        }
        if (compare(rule, "useTriggers")) {
            _rules.useTriggers = _rules.useTriggers ? false : true;
        }
        if (compare(rule, "useOracleQuotes")) {
            _flow.useOracleQuotes = _flow.useOracleQuotes ? false : true;
        }
    }

    function toggleTriggers(bytes memory trigger) public onlyValidator {
        if (compare(trigger, "useSelector")) {
            _tRules.useSelector = _tRules.useSelector ? false : true;
        }
        if (compare(trigger, "useSelectorParams")) {
            _tRules.useSelectorParams ? false : _tRules.useSelector = true;
            _tRules.useSelectorParams = _tRules.useSelectorParams ? false : true;
        }
        if (compare(trigger, "useStrictDestination")) {
            _tRules.useStrictDestination = _tRules.useStrictDestination ? false : true;
        }
        if (compare(trigger, "useMsgValue")) {
            _tRules.useMsgValue = _tRules.useMsgValue ? false : true;
        }
    }

    /// @dev internal function for access control
    /// @param addressToCheck - to address to satisfy
    /// @return truthy - true / false depending if the user passed all provided checks
    function _satisfy(address addressToCheck, uint256 providedNonce)
        internal
        virtual
        returns (bool truthy)
    {
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
        bytes calldata msgData
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
