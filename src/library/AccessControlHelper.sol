// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct AccessControlSchema {
    uint128 maxNonce;
    uint128 ERC20GateValue;
    address ERC20GateContract;
    address NFTGateContract;
}

library AccessControlHelper {
    function getPayload(address from) public pure returns (bytes memory payload) {
        payload = new bytes(36);
        assembly {
            mstore(add(payload, 32), 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(add(payload, 36), from)
        }
    }

    function ERC20Gate(address erc20Contract, uint256 value, address from) public view returns (bool) {
        return staticCall(getPayload(from), erc20Contract) >= value;
    }

    function NFTGate(address nftContract, address from) public view returns (bool) {
        return staticCall(getPayload(from), nftContract) >= 1;
    }

    function validNonce(AccessControlSchema memory schema, uint256 providedNonce) public pure returns (bool) {
        return schema.maxNonce == 0 || schema.maxNonce >= providedNonce;
    }

    function previewAccess(AccessControlSchema memory schema, address caller) public view returns (bool) {
        bool nftGateResult = schema.NFTGateContract == address(0) || NFTGate(schema.NFTGateContract, caller);
        bool erc20GateResult = schema.ERC20GateContract == address(0) ||
            schema.ERC20GateValue == 0 ||
            ERC20Gate(schema.ERC20GateContract, schema.ERC20GateValue, caller);
        return nftGateResult && erc20GateResult;
    }

    function staticCall(bytes memory _payload, address _to) public view returns (uint256) {
        (bool success, bytes memory returnData) = _to.staticcall(_payload);
        require(success, "staticcall operation failed");
        return abi.decode(returnData, (uint256));
    }
}
