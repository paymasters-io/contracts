// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Oracle, IERC20Metadata, IERC20, TokenInfo} from "@paymasters-io/interfaces/oracles/IOracleHelper.sol";

error TokenNotSupported(address token);
error PriceMarkupOutOfBounds(uint256 upper, uint256 lower);
error TokenNotSpecified();

interface IERC20Paymaster {
    event UserOperationSponsored(
        address indexed user,
        uint256 actualTokenCharge,
        uint256 actualGasCost,
        uint256 actualTokenPrice
    );

    event PostOpReverted(address indexed user, uint256 preCharge);

    event OracleChanged(Oracle newOracle);

    event TokenAdded(
        address indexed tokenAddress,
        address feed,
        uint256 priceMarkup,
        uint256 priceMaxAge
    );

    event TokenRemoved(address indexed tokenAddress);

    function setOracle(Oracle _oracle) external;

    function addToken(IERC20Metadata token, TokenInfo memory _tokenInfo) external;

    function removeToken(IERC20Metadata token) external;

    function withdraw(IERC20Metadata token, address to, uint256 amount) external;
}
