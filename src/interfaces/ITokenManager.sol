// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@paymasters-io/interfaces/ICore.sol";
import "@paymasters-io/library/OracleHelper.sol";

interface ITokenManager is ICore {
    function setDefaultOracle(Oracle oracle) external;

    // do not use a ticker oracle with a proxy/feed or vice versa
    function addTokenTicker(IERC20 token, string memory ticker) external;

    function addTokenProxyOrFeed(IERC20 token, address proxyOrFeed) external;
}
