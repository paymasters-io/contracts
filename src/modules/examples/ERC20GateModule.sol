// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/modules/BaseModule.sol";
import "@paymasters-io/library/AccessControl.sol";

/// NOTE:::PLEASE NOTE this serves as prototype for future modules
/// can support more use cases such as:
/// - require user to have a certain amount of tokens and/or a certain amount of ETH
/// - require user to have a certain amount of tokens and to have performed a certain action on specific contract
/// - require user to have a certain amount of tokens and to have a good onchain credit rating
/// - require user to have a certain amount of tokens and to be involved in a DeFi protocol
/// - require user to have a certain amount of tokens and to be human verified with worldId
contract ERC20GateModule is BaseModule {
    using AccessControlBase for address;

    address public immutable erc20Token;
    uint256 public immutable minAmount;

    constructor(
        address _token,
        uint256 _minAmount,
        address _paymaster,
        address _moduleAttester,
        address _manager
    ) BaseModule(_paymaster, _moduleAttester, _manager) {
        erc20Token = _token;
        minAmount = _minAmount;
    }

    function register() external payable override returns (address) {
        return super.register(true);
    }

    function _validate(
        bytes calldata /** verificationData */,
        address user
    ) internal view virtual override returns (bool) {
        return erc20Token.ERC20Gate(minAmount, user);
    }

    function _postValidate(
        bytes32 moduleData,
        uint256 actualGasCost,
        address sender
    ) internal virtual override {}

    receive() external payable virtual override {}
}
