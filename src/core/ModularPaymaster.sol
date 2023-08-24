// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// eth-infinitsm
import "@aa/contracts/core/BasePaymaster.sol";
import "@aa/contracts/core/Helpers.sol";
import "@aa/contracts/interfaces/UserOperation.sol";
import "@aa/contracts/interfaces/IEntryPoint.sol";

contract ModularPaymaster is BasePaymaster {
    constructor(IEntryPoint _entryPoint, address _owner) BasePaymaster(_entryPoint) Ownable(_owner) {}

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationResult) {
        unchecked {
            validationResult = 1;
        }
    }

    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        unchecked {}
    }
}
