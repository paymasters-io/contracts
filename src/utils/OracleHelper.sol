// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@paymasters-io/interfaces/oracles/IProxy.sol";
import "@paymasters-io/interfaces/oracles/ISupraConsumer.sol";
import "@paymasters-io/interfaces/oracles/IOracleHelper.sol";

abstract contract AbstractStore {
    IERC20Metadata constant native = IERC20Metadata(address(0x0));

    uint224 constant PRICE_DENOMINATOR = 1e26;
    uint32 constant REFUND_POSTOP_COST = 41000;

    uint224 ttl = 0;
    uint32 updateThreshold = 0;

    mapping(IERC20Metadata => TokenInfo) _tokenInfo;
    mapping(IERC20Metadata => Cache) _cache;

    Oracle public oracle = Oracle.CHAINLINK;
}

contract OracleHelper is AbstractStore, IOracleHelper {
    function getNativeToken() public view returns (TokenInfo memory) {
        return _tokenInfo[native];
    }

    function updatePrice(OracleQuery memory query, Oracle _oracle, bool force) public returns (uint256) {
        Cache memory cache = _cache[query.token];
        uint256 cacheAge = block.timestamp - cache.timestamp;
        if (!force && cacheAge <= ttl) {
            return cache.price;
        }

        TokenInfo memory base = _tokenInfo[query.base];
        TokenInfo memory token = _tokenInfo[query.token];
        _requiresValidDecimalsForPair(query, base.decimals, token.decimals);

        uint256 price;
        if (_oracle == Oracle.CHAINLINK) {
            price = getPriceFromChainlink(base.proxyOrFeed, token.proxyOrFeed, token.decimals);
        } else if (_oracle == Oracle.SUPRA) {
            price = getPriceFromSupra(base.proxyOrFeed, base.ticker, token.ticker, token.decimals);
        } else {
            price = getPriceFromAPI3DAO(base.proxyOrFeed, token.proxyOrFeed, token.decimals);
        }

        uint256 _updateThreshold = updateThreshold;
        uint256 priceNewByOld = (price * PRICE_DENOMINATOR) / cache.price;
        bool updateRequired = force ||
            priceNewByOld > PRICE_DENOMINATOR + _updateThreshold ||
            priceNewByOld < PRICE_DENOMINATOR - _updateThreshold;
        if (!updateRequired) {
            return cache.price;
        }

        _cache[query.token].price = uint192(price);
        cache.timestamp = uint64(block.timestamp);
        _cache[query.token].timestamp = cache.timestamp;
        emit TokenPriceUpdated(address(query.token), price, cache.price, cache.timestamp);
        return price;
    }

    function getPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint256 decimals
    ) public view returns (uint256) {
        (uint80 roundId, int256 basePrice, , uint256 updatedAt, uint80 answeredInRound) = AggregatorV3Interface(
            baseFeed
        ).latestRoundData();
        _requiresAnswerInRound(roundId, updatedAt, answeredInRound);
        (uint80 tRoundId, int256 tokenPrice, , uint256 tUpdatedAt, uint80 tAnsweredInRound) = AggregatorV3Interface(
            tokenFeed
        ).latestRoundData();
        _requiresAnswerInRound(tRoundId, tUpdatedAt, tAnsweredInRound);
        _requiresPriceGreaterThanZero(uint(basePrice), uint(tokenPrice));
        return (decimals * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint256 decimals
    ) public view returns (uint256) {
        (int256 basePrice, ) = ISupraConsumer(priceFeed).checkPrice(baseTicker);
        (int256 tokenPrice, ) = ISupraConsumer(priceFeed).checkPrice(tokenTicker);
        _requiresPriceGreaterThanZero(uint(basePrice), uint(tokenPrice));
        return (decimals * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getPriceFromAPI3DAO(
        address baseProxy,
        address tokenProxy,
        uint256 decimals
    ) public view returns (uint256) {
        (int224 basePrice, ) = IProxy(baseProxy).read();
        (int224 tokenPrice, ) = IProxy(tokenProxy).read();
        _requiresPriceGreaterThanZero(uint224(basePrice), uint224(tokenPrice));
        return (decimals * uint224(basePrice)) / uint224(tokenPrice);
    }

    function _requiresAnswerInRound(uint80 roundId, uint256 updatedAt, uint80 answeredInRound) internal view {
        uint256 two_four_hours = block.timestamp - 60 * 60 * 24 * 2;
        if (updatedAt < two_four_hours || answeredInRound < roundId) revert StalePrice();
    }

    function _requiresPriceGreaterThanZero(uint256 a, uint256 b) internal pure {
        if (a <= 0 || b <= 0) revert PriceIsZeroOrLess(a, b);
    }

    function _requiresValidDecimalsForPair(OracleQuery memory self, uint256 a, uint256 b) internal pure {
        if (a < 6 || b < 6) revert UnknownTokenPair(self.base, self.token);
    }

    function _setUpdateThresholdAndTTL(uint32 _threshold, uint224 _ttl) internal {
        if (_threshold > 1e6) revert UpdateThresholdTooHigh(_threshold);
        updateThreshold = _threshold;
        ttl = _ttl;
    }
}
