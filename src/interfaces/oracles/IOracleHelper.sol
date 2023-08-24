// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

enum Oracle {
    CHAINLINK,
    SUPRA,
    API3
}

struct OracleQuery {
    IERC20Metadata base;
    IERC20Metadata token;
}

struct TokenInfo {
    address proxyOrFeed;
    string ticker;
    uint256 priceMarkup;
    uint248 priceMaxAge;
    uint8 decimals;
}

struct Cache {
    uint192 price;
    uint96 timestamp;
    uint96 updateThreshold;
    uint128 ttl;
}

error PriceIsZeroOrLess(uint256 a, uint256 b);
error UnknownTokenPair(IERC20Metadata base, IERC20Metadata token);

interface IOracleHelper {
    event TokenPriceUpdated(
        address indexed tokenAddress,
        uint256 currentPrice,
        uint256 previousPrice,
        uint256 cachedPriceTimestamp
    );

    function getNativeToken() external view returns (TokenInfo memory);

    function updatePrice(OracleQuery memory self, Oracle oracle) external;

    function getPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint256 decimals
    ) external view returns (uint256);

    function getPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint256 decimals
    ) external view returns (uint256);

    function getPriceFromAPI3DAO(
        address baseProxy,
        address tokenProxy,
        uint256 decimals
    ) external view returns (uint256);
}
