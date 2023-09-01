// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct Module {
    address manager;
    bool requiresSig;
    bool registered;
    bool attested;
    uint256 balance;
}

error DepositAmountTooLow(uint256 amount);
error InsufficientFunds(uint256 balance, uint256 amount);
error FailedToWithdrawEth(address receiver, uint256 amount);
error NotAuthorized(address sender);
error FailedToRegisterModule(address module);
error FailedToDeRegisterModule(address module);
error InvalidPaymasterData(string reason);
error NullReceiver();
error NullProxy();

interface IModule {
    event DepositSuccess(uint256 value);
    event PaymasterDepositSuccess(uint256 amount);
    event WithdrawSuccess(uint256 amount, address receiver);
    event PaymasterWithdrawSuccess(uint256 amount);

    // returns deposit in paymaster
    function getDeposit() external view returns (uint256);

    // funds the verifying paymaster from caller
    function deposit() external payable;

    // funds the verifying paymaster from module balance;
    function deposit(uint256 amount) external;

    // defunds the verifying paymaster
    function withdrawFromPaymaster(uint256 amount) external;

    // withdraws the balances from this module
    function withdraw(uint256 amount, address receiver) external;

    // registers module on paymaster
    function register() external payable returns (address);

    // deregisters module on paymaster
    function deRegister() external returns (address);

    // used to validate the user operation.
    function validate(bytes calldata paymasterAndData, address user) external view returns (bool);

    // post operation hook
    function postValidate(bytes32 moduleData, uint256 actualGasCost, address sender) external;
}
