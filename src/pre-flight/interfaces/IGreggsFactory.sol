// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGreggsFactory {
    // deploy general flow paymaster
    function deployA(
        bytes32 salt,
        bytes calldata metadata,
        bool[4] memory rules,
        uint128 maxNonce,
        uint128 ERC20GateValue,
        address ERC20GateContract,
        address NFTGateContract,
        address validationAddress
    ) external;

    // deploy approval based flow paymaster
    function deployB(
        bytes32 salt,
        bytes calldata metadata,
        bool[4] memory rules,
        uint128 maxNonce,
        uint128 ERC20GateValue,
        address ERC20GateContract,
        address NFTGateContract,
        address validationAddress
    ) external;
}
