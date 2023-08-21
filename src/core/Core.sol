// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@paymasters-io/library/AccessControlHelper.sol";
import "@paymasters-io/library/SignatureValidationHelper.sol";
import "@paymasters-io/library/Errors.sol";
import "@paymasters-io/security/Guard.sol";
import "@paymasters-io/interfaces/ICore.sol";

/// @notice validation and access-control impl that can be reused in any EVM or zkEVM paymaster
abstract contract Core is ICore, Guard {
    using MessageHashUtils for bytes32;
    using AccessControlHelper for AccessControlSchema;
    using SignatureValidationHelper for bytes;

    address public rebateContract;
    address public vaa; // validation address
    uint256 public maxNonce;

    mapping(address => bool) public isDelegator;
    mapping(address => bool) public isDestination;

    AccessControlSchema public accessControlSchema;
    SigConfig public signatureConf;

    // debt mechanism is used to track the debt of a delegator.
    mapping(address => uint256) public delegatorsToDebt;

    modifier isAuthorized() {
        if (msg.sender != vaa) revert UnAuthorized();
        _;
    }

    function setNodeSigners(address primarySigner, address secondarySigner, uint256 sigCount) external isAuthorized {
        if (sigCount > 2) revert InvalidConfig();
        signatureConf.verifyingSigner1 = primarySigner;
        signatureConf.verifyingSigner2 = secondarySigner;
        signatureConf.validNumOfSignatures = SigCount(sigCount);
    }

    function setDelegator(address delegator, bool value) external isAuthorized {
        isDelegator[delegator] = value;
    }

    function setStrictDestination(address destination, bool value) external isAuthorized {
        isDestination[destination] = value;
    }

    function setAccessControlSchema(AccessControlSchema calldata schema) external isAuthorized {
        accessControlSchema = schema;
    }

    function setVAA(address _vaa) external isAuthorized {
        vaa = _vaa;
    }

    function setMaxNonce(uint256 _maxNonce) external isAuthorized {
        maxNonce = _maxNonce;
    }

    function setRebateContract(address _rebateContract) external isAuthorized {
        rebateContract = _rebateContract;
    }

    function previewAccess(address user) public view virtual returns (bool) {
        return accessControlSchema.previewAccess(user);
    }

    function previewValidation(bytes calldata paymasterAndData, address caller) external view virtual returns (bool) {
        return _validate(paymasterAndData, caller);
    }

    function withdraw() external whenNotPaused isAuthorized {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) revert OperationFailed();
    }

    function payDebt(address debtor) public payable whenNotPaused {
        delegatorsToDebt[debtor] -= msg.value;
    }

    function _validateWithDelegation(
        bytes calldata paymasterAndData,
        address caller,
        address delegator
    ) internal view virtual returns (bool) {
        return IDelegator(delegator).previewValidation(paymasterAndData, caller);
    }

    function _validateWithoutDelegation(
        bytes calldata paymasterAndData,
        address caller
    ) internal view virtual returns (bool) {
        return _validate(paymasterAndData, caller);
    }

    function _validate(bytes calldata paymasterAndData, address caller) private view returns (bool success) {
        _beforeValidation(caller);
        SigConfig memory _signatureConf = signatureConf;

        bytes32 hash = 0x0;
        bytes memory signatures = new bytes(0);

        if (paymasterAndData.length > 52) {
            hash = keccak256(paymasterAndData[20:52]).toEthSignedMessageHash();
            signatures = paymasterAndData[52:];
        }

        if (accessControlSchema.onchainPreviewEnabled && !previewAccess(caller)) revert AccessDenied();

        SigCount expectedValidationStep = _signatureConf.validNumOfSignatures;
        if (expectedValidationStep == SigCount.ONE) {
            if (_signatureConf.verifyingSigner1 == address(0) && _signatureConf.verifyingSigner2 == address(0)) {
                revert FailedToValidateOp();
            }
            require(paymasterAndData.length > 52, "hash or sig possibly 0x0");
            address signer = signatures.validateOneSignature(hash);
            success = (signer == _signatureConf.verifyingSigner1 || signer == _signatureConf.verifyingSigner2);
        } else if (expectedValidationStep == SigCount.TWO) {
            if (_signatureConf.verifyingSigner1 == address(0) || _signatureConf.verifyingSigner2 == address(0)) {
                revert FailedToValidateOp();
            }
            require(paymasterAndData.length > 52, "hash or sig possibly 0x0");
            (address primarySigner, address secondarySigner) = signatures.validateTwoSignatures(hash);
            success =
                (primarySigner == _signatureConf.verifyingSigner1 &&
                    secondarySigner == _signatureConf.verifyingSigner2) ||
                (primarySigner == _signatureConf.verifyingSigner2 &&
                    secondarySigner == _signatureConf.verifyingSigner1);
        } else {
            success = true;
        }
        _afterValidation(caller);
    }

    function _beforeValidation(address caller) internal view virtual {
        (caller);
    }

    function _afterValidation(address caller) internal view virtual {
        (caller);
    }
}
