// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract BaseModule {
    address public immutable paymaster;

    error NotAuthorized(address sender);

    constructor(address _paymaster, address _vaa, bool _requiresVaaSig) {
        // _paymaster.registerModule(_vaa, _requiresVaaSig);
        paymaster = _paymaster;
    }

    modifier onlyPaymastersIo() {
        if (msg.sender != paymaster) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    // funds the verifying paymaster
    function stake() external payable virtual;

    // defunds the verifying paymaster
    function unstake(uint256 amount) external virtual;

    // withdraws the balances from this module
    function withdraw() external virtual;

    // returns the stake of the user
    function getStake(address user) external view virtual returns (uint256);

    // used to validate the user operation.
    // called by paymaster.io
    function validate(bytes calldata paymasterAndData, address user) external view virtual returns (bool);

    // post operation hook
    // called by paymaster.io
    function postValidate(bytes calldata context, uint256 actualGasCost, address user) external virtual;

    // internal function that must be overidden by the inheriting module
    function _validate(bytes calldata paymasterAndData, address user) internal view virtual returns (bool);

    // internal function that must be overidden by the inheriting module
    function _postValidate(bytes calldata context, uint256 actualGasCost, address user) internal virtual;

    // fallback to receive ether
    receive() external payable virtual;
}
