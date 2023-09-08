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
    uint64 priceMaxAge;
    uint32 priceMarkup;
    uint8 decimals;
    string ticker;
    address proxyOrFeed;
}

struct Cache {
    uint192 price;
    uint64 timestamp;
}

error PriceIsZeroOrLess(int256 a, int256 b);
error UnknownTokenPair(address base, address token);
error UpdateThresholdTooHigh(uint32 updateThreshold);
error StalePrice();

interface IOracleHelper {
    event TokenPriceUpdated(
        address indexed tokenAddress,
        uint192 currentPrice,
        uint192 previousPrice,
        uint64 cachedPriceTimestamp
    );

    function getNativeToken() external view returns (TokenInfo memory);

    function updatePrice(
        OracleQuery memory self,
        Oracle oracle,
        bool force
    ) external returns (uint192);

    function getPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint8 decimals
    ) external view returns (uint256);

    function getPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint8 decimals
    ) external view returns (uint256);

    function getPriceFromAPI3DAO(
        address baseProxy,
        address tokenProxy,
        uint8 decimals
    ) external view returns (uint256);
}
