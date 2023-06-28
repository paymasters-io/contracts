// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@paymasters-io/library/PaymasterOperationsHelper.sol";

struct AccessControlSchema {
    uint128 maxNonce;
    uint128 ERC20GateValue;
    address ERC20GateContract;
    address NFTGateContract;
}

library AccessControlHelper {
    using PaymasterOperationsHelper for bytes;

    function ERC20Gate(address erc20Contract, uint256 value, address from) public view returns (bool) {
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", from);
        return _externalCall(payload, erc20Contract, value);
    }

    function NFTGate(address nftContract, address from) public view returns (bool) {
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", from);
        return _externalCall(payload, nftContract, 1);
    }

    function validNonce(AccessControlSchema memory schema, uint256 providedNonce) public pure returns (bool truthy) {
        if (schema.maxNonce == 0) return true;
        truthy = schema.maxNonce >= providedNonce;
    }

    function previewAccess(AccessControlSchema memory schema, address caller) public view returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.

        if (schema.NFTGateContract != address(0)) {
            truthy = truthy && NFTGate(schema.NFTGateContract, caller);
        }

        if (schema.ERC20GateContract != address(0) && schema.ERC20GateValue > 0) {
            truthy = truthy && ERC20Gate(schema.ERC20GateContract, schema.ERC20GateValue, caller);
        }
    }

    function _externalCall(bytes memory _payload, address _to, uint256 _value) private view returns (bool) {
        return _payload.staticCall(_to) >= _value;
    }
}
