// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/library/AccessControl.sol";
import "@paymasters-io/modules/BaseModule.sol";

/// NOTE:::PLEASE NOTE this serves as prototype for future modules
/// can support more use cases such as:
/// - require user to have a certain amount of nft
/// - require user to have a certain amount of nft and to have performed a certain action on specific contract
/// - require user to have a certain amount of nft and to have a good onchain credit rating
/// - require user to have a certain amount of nft and to be involved in a DeFi protocol
/// - require user to have a certain amount of nft and to be human verified with worldId
contract NFTGateModule is BaseModule {
    using AccessControlBase for address;
    address public immutable erc721Token;

    constructor(
        address _token,
        address _paymaster,
        address _moduleAttester,
        address _manager
    ) BaseModule(_paymaster, _moduleAttester, _manager) {
        erc721Token = _token;
    }

    function register() external payable override returns (address) {
        return super.register(true);
    }

    function _validate(
        bytes calldata /** verificationData */,
        address user
    ) internal view virtual override returns (bool) {
        return erc721Token.NFTGate(user);
    }

    function _postValidate(
        bytes32 moduleData,
        uint256 actualGasCost,
        address sender
    ) internal virtual override {}

    receive() external payable virtual override {}
}
