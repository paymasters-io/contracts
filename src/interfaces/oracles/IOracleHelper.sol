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
    uint216 priceMaxAge;
    uint32 priceMarkup;
    uint8 decimals;
}

struct Cache {
    uint192 price;
    uint64 timestamp;
}

error PriceIsZeroOrLess(uint256 a, uint256 b);
error UnknownTokenPair(IERC20Metadata base, IERC20Metadata token);
error UpdateThresholdTooHigh(uint32 updateThreshold);
error StalePrice();

interface IOracleHelper {
    event TokenPriceUpdated(
        address indexed tokenAddress,
        uint256 currentPrice,
        uint256 previousPrice,
        uint256 cachedPriceTimestamp
    );

    function getNativeToken() external view returns (TokenInfo memory);

    function updatePrice(OracleQuery memory self, Oracle oracle, bool force) external returns (uint256);

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
