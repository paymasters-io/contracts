// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/interfaces/IModule.sol";
import "@paymasters-io/interfaces/IModuleAttestations.sol";
import "@paymasters-io/interfaces/IModularPaymaster.sol";
import "@paymasters-io/utils/Semver.sol";

abstract contract BaseModule is Semver, IModule {
    IModularPaymaster immutable paymaster;
    IModuleAttestations immutable moduleAttester;
    address immutable manager;

    constructor(address _paymaster, address _moduleAttester, address _manager) Semver(1, 0, 0) {
        paymaster = IModularPaymaster(_paymaster);
        moduleAttester = IModuleAttestations(_moduleAttester);
        manager = _manager;
    }

    modifier onlyPaymaster() {
        if (msg.sender != address(paymaster)) revert NotAuthorized(msg.sender);
        _;
    }

    modifier onlyManager() {
        if (msg.sender != manager) revert NotAuthorized(msg.sender);
        _;
    }

    function getDeposit() external view returns (uint256) {
        return paymaster.balanceOf(address(this));
    }

    function deposit() external payable {
        if (msg.value < 1e16) revert DepositAmountTooLow(msg.value);
        paymaster.depositFromModule{value: msg.value}();
        emit DepositSuccess(msg.value);
    }

    function deposit(uint256 amount) external onlyManager {
        uint256 balance = address(this).balance;
        if (balance < amount) revert InsufficientFunds(balance, amount);
        paymaster.depositFromModule{value: balance}();
        emit PaymasterDepositSuccess(amount);
    }

    function withdrawFromPaymaster(uint256 amount) external onlyManager {
        paymaster.withdrawToModule(amount);
        emit PaymasterWithdrawSuccess(amount);
    }

    function withdraw(uint256 amount, address receiver) external onlyManager {
        if (receiver == address(0)) revert NullReceiver();
        uint256 balance = address(this).balance;
        if (balance < amount) revert InsufficientFunds(balance, amount);
        (bool sent, ) = receiver.call{value: amount}("");
        if (!sent) revert FailedToWithdrawEth(receiver, amount);
        emit WithdrawSuccess(amount, receiver);
    }

    function register(bool requireSig) public payable returns (address module) {
        module = _register(manager, requireSig);
    }

    function deRegister() external onlyManager returns (address module) {
        module = paymaster.deregisterModule();
        if (module != address(this)) revert FailedToDeRegisterModule(address(this));
    }

    function validate(
        bytes calldata paymasterAndData,
        address user
    ) external view onlyPaymaster returns (bool) {
        return _validate(paymasterAndData, user);
    }

    function postValidate(
        bytes32 moduleData,
        uint256 actualGasCost,
        address sender
    ) external onlyPaymaster {
        _postValidate(moduleData, actualGasCost, sender);
    }

    function _register(
        address _manager,
        bool _requireSig
    ) internal onlyManager returns (address module) {
        uint256 fee = moduleAttester.getAttestationFee();
        address self = address(this);
        if (msg.value < fee) revert InsufficientFunds(msg.value, fee);
        bool success = moduleAttester.applyForAttestations{value: msg.value}();
        if (!success) revert FailedToRegisterModule(self);
        module = paymaster.registerModule(_manager, _requireSig);
        if (module != self) revert FailedToRegisterModule(self);
    }

    function _validate(
        bytes calldata paymasterAndData,
        address user
    ) internal view virtual returns (bool);

    function _postValidate(
        bytes32 moduleData,
        uint256 actualGasCost,
        address sender
    ) internal virtual;

    receive() external payable virtual;
}
