// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPlumStore} from "../interfaces/IPlumStore.sol";
import {DEPLOYER_SYSTEM_CONTRACT} from "@matterlabs/zksync-contracts/l2/system-contracts/Constants.sol";
import {SystemContractsCaller} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/SystemContractsCaller.sol";

contract GreggsFactory {
    // general
    bytes32 public bytecodeHashA;
    // approval based
    bytes32 public bytecodeHashB;
    // alternate store on zksync
    IPlumStore private _greggKeeper;

    event PaymasterDeployedEvent(address paymaster, bytes metadata, address owner);

    constructor(
        bytes32 _bytecodeHashA,
        bytes32 _bytecodeHashB,
        address plumStore
    ) {
        bytecodeHashA = _bytecodeHashA;
        bytecodeHashB = _bytecodeHashB;
        _greggKeeper = IPlumStore(plumStore);
    }

    // deploys a paymaster
    function deploy(
        bytes32 salt,
        bytes calldata metadata,
        bool[4] memory rules,
        uint128 maxNonce,
        uint128 ERC20GateValue,
        address ERC20GateContract,
        address NFTGateContract,
        address validationAddress,
        bool aOrB // true for general, false for approval based
    ) public returns (address contractAddress) {
        bytes memory arg = abi.encode(
            metadata,
            rules,
            maxNonce,
            ERC20GateValue,
            ERC20GateContract,
            NFTGateContract,
            validationAddress
        );
        contractAddress = _deploy(salt, aOrB ? bytecodeHashA : bytecodeHashB, arg);
        _greggKeeper.save(validationAddress, contractAddress, metadata);
        emit PaymasterDeployedEvent(contractAddress, metadata, validationAddress);
    }

    function _deploy(
        bytes32 salt,
        bytes32 bytecodeHash,
        bytes memory input
    ) internal returns (address paymasterAddress) {
        (bool success, bytes memory returnData) = SystemContractsCaller.systemCallWithReturndata(
            uint32(gasleft()),
            address(DEPLOYER_SYSTEM_CONTRACT),
            uint128(0),
            abi.encodeCall(DEPLOYER_SYSTEM_CONTRACT.create2, (salt, bytecodeHash, input))
        );
        require(success, "Deployment Failed");
        (paymasterAddress) = abi.decode(returnData, (address));
    }
}
