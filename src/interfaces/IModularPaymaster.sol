// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IModularPaymaster {
    event UserOperationSponsored(address indexed sender, uint256 actualGasCost, address module);
    event Deposit(address indexed module, uint256 value);
    event Withdrawal(address indexed module, uint256 amount);
    event Registered(
        address indexed module,
        address manager,
        bool requiresSig,
        uint256 value,
        uint256 timestamp
    );
    event DeRegistered(address indexed module, uint256 timestamp);

    // gets the balance of the module from the paymaster
    function balanceOf(address user) external view returns (uint256);

    // deposits fund to the paymaster
    function depositFromModule() external payable;

    // withdraws funds from the paymaster
    function withdrawToModule(uint256 amount) external;

    // registers a module
    function registerModule(address manager, bool requiresSig) external payable returns (address);

    // de-registers a module
    function deregisterModule() external returns (address);
}
