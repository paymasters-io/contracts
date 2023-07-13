// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct AccessControlSchema {
    uint256 ERC20GateValue;
    address ERC20GateContract;
    address NFTGateContract;
    bool onchainPreviewEnabled;
}

library AccessControlHelper {
    function getPayload(address from) public pure returns (bytes memory payload) {
        payload = new bytes(36);
        assembly {
            mstore(add(payload, 32), hex"70a08231")
            mstore(add(payload, 36), from)
        }
    }

    function ERC20Gate(address erc20Contract, uint256 value, address from) public view returns (bool) {
        return staticCall(getPayload(from), erc20Contract) >= value;
    }

    function NFTGate(address nftContract, address from) public view returns (bool) {
        return staticCall(getPayload(from), nftContract) >= 1;
    }

    function previewAccess(AccessControlSchema memory schema, address caller) public view returns (bool) {
        bool nftGateResult = schema.NFTGateContract == address(0) || NFTGate(schema.NFTGateContract, caller);
        bool erc20GateResult = schema.ERC20GateContract == address(0) ||
            schema.ERC20GateValue == 0 ||
            ERC20Gate(schema.ERC20GateContract, schema.ERC20GateValue, caller);
        return nftGateResult && erc20GateResult;
    }

    function staticCall(bytes memory _payload, address _to) public view returns (uint256) {
        bytes memory returnData;
        assembly {
            let success := staticcall(gas(), _to, add(_payload, 0x20), mload(_payload), mload(0x40), 0)
            if iszero(success) {
                revert(add(0x20, "staticcall operation failed"), 24)
            }
            let returnDataSize := returndatasize()
            returnData := mload(0x40)
            mstore(0x40, add(returnData, add(returnDataSize, 0x20)))
            mstore(returnData, returnDataSize)
            returndatacopy(add(returnData, 0x20), 0, returnDataSize)
        }
        return abi.decode(returnData, (uint256));
    }
}
