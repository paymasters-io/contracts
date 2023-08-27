// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error DepositAmountTooLow(uint256 amount);
error InsufficientFunds(uint256 balance, uint256 amount);
error FailedToWithdrawEth(address receiver, uint256 amount);
error NotAuthorized(address sender);
error FailedToRegisterModule(address module);
error FailedToDeRegisterModule(address module);
error NullReceiver();

interface IModule {
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
    function register() external returns (address);

    // deregisters module on paymaster
    function deRegister() external returns (address);

    // used to validate the user operation.
    function validate(bytes calldata paymasterAndData, address user) external view returns (bool);

    // post operation hook
    function postValidate(bytes calldata context, uint256 actualGasCost) external;
}
