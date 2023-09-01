// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// eth-infinitsm
import "@aa/contracts/core/BasePaymaster.sol";
import "@aa/contracts/core/Helpers.sol";
import "@aa/contracts/interfaces/UserOperation.sol";
import "@aa/contracts/interfaces/IEntryPoint.sol";
// paymasters.io
import "@paymasters-io/interfaces/IModule.sol";
import "@paymasters-io/interfaces/IModularPaymaster.sol";
import "@paymasters-io/interfaces/IModuleAttestations.sol";
import "@paymasters-io/library/SignatureValidation.sol";

contract ModularPaymaster is BasePaymaster, IModularPaymaster {
    using UserOperationLib for UserOperation;
    using SignatureValidation for bytes;

    IModuleAttestations immutable _attester;
    mapping(address => Module) _modules;

    constructor(
        IEntryPoint _entryPoint,
        IModuleAttestations attester,
        address _owner
    ) BasePaymaster(_entryPoint) Ownable(_owner) {
        _attester = attester;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _modules[user].balance;
    }

    // deposits fund to the paymaster
    function depositFromModule() external payable {
        _modules[msg.sender].balance += msg.value;
    }

    // withdraws funds from the paymaster
    function withdrawToModule(uint256 amount) external {
        Module memory module = _modules[msg.sender];
        if (module.balance < amount) revert InsufficientFunds(module.balance, amount);
        _modules[msg.sender].balance -= amount;
        (bool sent, ) = module.manager.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(module.manager, amount);
    }

    // registers a module
    function registerModule(address manager, bool requiresSig) external payable returns (address) {
        if (_modules[msg.sender].registered) revert FailedToRegisterModule(msg.sender);
        _modules[msg.sender] = Module(manager, requiresSig, true, false, msg.value);
        return msg.sender;
    }

    // de-registers a module
    function deregisterModule() external returns (address) {
        if (!_modules[msg.sender].registered) revert FailedToDeRegisterModule(msg.sender);
        _modules[msg.sender].registered = false;
        return msg.sender;
    }

    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        address sender = userOp.getSender();
        return
            keccak256(
                abi.encode(
                    sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    block.chainid,
                    address(this),
                    validUntil,
                    validAfter
                )
            );
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 requiredPreFund
    ) internal view override returns (bytes memory context, uint256 validationResult) {
        uint256 moduleDataOffset = 20 + 20;
        // 32 bytes of free memory
        uint256 timestampOffset = 32 + moduleDataOffset;
        uint256 signatureOffset = 12 + timestampOffset;

        if (userOp.paymasterAndData.length < signatureOffset + 64)
            revert InvalidPaymasterData("length");

        address module = address(bytes20(userOp.paymasterAndData[20:moduleDataOffset]));

        uint48 validUntil = uint48(
            bytes6(userOp.paymasterAndData[timestampOffset:timestampOffset + 6])
        );
        uint48 validAfter = uint48(
            bytes6(userOp.paymasterAndData[signatureOffset - 6:signatureOffset])
        );
        bytes memory signature = userOp.paymasterAndData[signatureOffset:];

        Module memory moduleData = _modules[module];

        if (!moduleData.registered || module == address(0)) revert InvalidPaymasterData("module");

        uint256 gasCost = requiredPreFund + (41000 * userOp.maxFeePerGas);
        if (moduleData.balance < gasCost) revert InsufficientFunds(moduleData.balance, gasCost);

        bytes32 hash = getHash(userOp, validUntil, validAfter);
        bool validationSuccess;

        /// NOTE:::PLEASE NOTE vs1 == module signer, vs2 == 2fa signer i.e paymasters.io
        if (moduleData.requiresSig) {
            (address vs1, address vs2) = signature.validateTwoSignatures(hash);
            validationSuccess = vs1 == moduleData.manager && vs2 == owner();
        } else {
            address vs1 = signature.validateOneSignature(hash);
            validationSuccess = vs1 == moduleData.manager;
        }

        context = abi.encodePacked(
            userOp.paymasterAndData[moduleDataOffset:timestampOffset],
            module,
            userOp.sender
        );
        validationResult = _packValidationData(!validationSuccess, validUntil, validAfter);
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        uint256 expectedCost = actualGasCost + 41000 * tx.gasprice;
        address module = address(bytes20(context[32:52]));

        if (mode == PostOpMode.postOpReverted) {
            _modules[module].balance -= expectedCost;
            return;
        }

        _modules[module].balance -= expectedCost;
        bytes32 moduleData = bytes32(context[0:32]);
        address sender = address(bytes20(context[52:]));

        if (_modules[module].attested) {
            IModule(module).postValidate(moduleData, expectedCost, sender);
        } else if (_attester.attestationResolved(module)) {
            _modules[module].attested = true;
            IModule(module).postValidate(moduleData, expectedCost, sender);
        }
    }
}
