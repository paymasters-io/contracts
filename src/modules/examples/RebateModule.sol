// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@paymasters-io/modules/BaseModule.sol";

/// NOTE:::PLEASE NOTE this serves as prototype for future modules
/// can support more use cases such as:
/// - refunds excess gas to user in form of ERC20 tokens
/// - rebates users who provide value above a threshold with ERC20 tokens
contract RebateModule is BaseModule {
    IERC20 public immutable rebateToken;
    uint256 public immutable rebate;

    constructor(
        IERC20 _token,
        uint256 _rebate,
        address _paymaster,
        address _moduleAttester,
        address _manager
    ) BaseModule(_paymaster, _moduleAttester, _manager) {
        rebate = _rebate;
        rebateToken = _token;
    }

    function register() external payable override returns (address) {
        return super.register(true);
    }

    function _validate(
        bytes calldata /** paymasterAndData */,
        address /** user */
    ) internal view virtual override returns (bool) {
        return true;
    }

    function _postValidate(bytes32 moduleData, uint256, address user) internal virtual override {
        uint256 valueProvided = uint256(moduleData);
        uint256 gasRebate = (valueProvided * rebate) / 100;
        if (gasRebate > 0) {
            bool success = rebateToken.transfer(user, gasRebate);
            require(success, "RebateModule: failed to transfer rebate");
        }
    }

    receive() external payable virtual override {}
}
