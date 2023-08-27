// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/modules/BaseModule.sol";
import "@paymasters-io/utils/Human.sol";

/// NOTE:::PLEASE NOTE this serves as prototype for future modules
/// can support more use cases such as:
/// - require user to be a real human verified with worldId
contract HumanVerifiedModule is BaseModule, Human {
    bool public immutable requireSig;

    constructor(
        IWorldID _worldId,
        string memory _appId,
        string memory _action,
        address _paymaster,
        address _manager,
        bool _requireSig
    ) BaseModule(_paymaster, _manager, _requireSig) Human(_worldId, _appId, _action) {
        requireSig = _requireSig;
    }

    function register() external override returns (address) {
        return super.register(requireSig);
    }

    function _validate(bytes calldata paymasterAndData, address /** */) internal view virtual override returns (bool) {
        (address signal, uint256 root, uint256 nullifierHash, uint256[8] memory proof) = abi.decode(
            paymasterAndData,
            (address, uint256, uint256, uint256[8])
        );
        return isHuman(signal, root, nullifierHash, proof);
    }

    function _postValidate(bytes calldata context, uint256 /** */) internal virtual override {
        uint256 nullifierHash = abi.decode(context, (uint256));
        _afterValidation(nullifierHash);
    }

    receive() external payable virtual override {}
}
