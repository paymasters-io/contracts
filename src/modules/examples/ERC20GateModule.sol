// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@paymasters-io/modules/BaseModule.sol";

/// NOTE:::PLEASE NOTE this serves as prototype for future modules
/// can support more use cases such as:
/// - require user to have a certain amount of tokens and/or a certain amount of ETH
/// - require user to have a certain amount of tokens and to have performed a certain action on specific contract
/// - require user to have a certain amount of tokens and to have a good onchain credit rating
/// - require user to have a certain amount of tokens and to be involved in a DeFi protocol
/// - require user to have a certain amount of tokens and to be human verified with worldId
contract ERC20GateModule is BaseModule {
    IERC20 public immutable erc20Token;
    uint256 public immutable minAmount;

    constructor(
        IERC20 _token,
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
        bytes calldata /** paymasterAndData */,
        address user
    ) internal view virtual override returns (bool) {
        uint256 balance = erc20Token.balanceOf(user);
        return balance >= minAmount;
    }

    function _postValidate(
        bytes calldata context,
        uint256 actualGasCost
    ) internal virtual override {}

    receive() external payable virtual override {}
}
