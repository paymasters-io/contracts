// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Core} from "@paymasters-io/core/Core.sol";
import "@paymasters-io/library/Errors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@paymasters-io/library/OracleHelper.sol";
import "@paymasters-io/interfaces/ITokenManager.sol";

abstract contract TokenManager is Core, ITokenManager {
    using SafeERC20 for IERC20;

    using OracleHelper for OracleQueryInput;
    struct TokenInfo {
        address proxyOrFeed;
        string ticker;
    }

    mapping(IERC20 => TokenInfo) public tokenToInfo;
    Oracle public defaultOracle = Oracle.API3;

    function setDefaultOracle(Oracle oracle) external isAuthorized {
        defaultOracle = oracle;
    }

    // do not use a ticker oracle with a proxy/feed or vice versa
    function addTokenTicker(IERC20 token, string calldata ticker) external isAuthorized {
        tokenToInfo[token].ticker = ticker;
    }

    function addTokenProxyOrFeed(IERC20 token, address proxyOrFeed) external isAuthorized {
        tokenToInfo[token].proxyOrFeed = proxyOrFeed;
    }

    function _getPriceFromOracle(IERC20 feeToken, uint256 amount) internal view returns (uint256) {
        OracleQueryInput memory input = OracleQueryInput(
            tokenToInfo[IERC20(address(0x0))].proxyOrFeed,
            tokenToInfo[feeToken].proxyOrFeed,
            tokenToInfo[IERC20(address(0x0))].ticker,
            tokenToInfo[feeToken].ticker
        );

        return input.getDerivedPrice(amount, defaultOracle);
    }

    function _validateToken(address feeToken) internal view {
        require(feeToken != address(0x0), "feeToken cannot be 0x0");

        if (
            tokenToInfo[IERC20(feeToken)].proxyOrFeed == address(0) ||
            bytes(tokenToInfo[IERC20(feeToken)].ticker).length == 0
        ) {
            revert TokenNotSupported(feeToken);
        }
    }

    /// paymasterAndData[4:24] : IERC20(feeToken) 20byte
    /// paymasterAndData[24:] : ...paymasterAndData
    function _validateWithDelegation(
        bytes calldata paymasterAndData,
        address caller,
        address delegator
    ) internal view override returns (bool) {
        address feeToken = address(bytes20(paymasterAndData[0:20]));
        _validateToken(feeToken);
        return super._validateWithDelegation(paymasterAndData[20:], caller, delegator);
    }

    function _validateWithoutDelegation(
        bytes calldata paymasterAndData,
        address caller
    ) internal view override returns (bool) {
        address feeToken = address(bytes20(paymasterAndData[4:24]));
        _validateToken(feeToken);
        return super._validateWithoutDelegation(paymasterAndData[24:], caller);
    }

    function _transferTokens(address from, IERC20 feeToken, uint256 amount) private nonReentrant whenNotPaused {
        feeToken.safeTransferFrom(from, vaa, amount);
    }
}
