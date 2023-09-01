// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@paymasters-io/interfaces/oracles/IAPI3Proxy.sol";
import "@paymasters-io/interfaces/oracles/ISupraConsumer.sol";
import "@paymasters-io/interfaces/oracles/IOracleHelper.sol";

abstract contract AbstractStore {
    IERC20Metadata constant native =
        IERC20Metadata(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));

    uint256 constant PRICE_DENOMINATOR = 1e26;
    uint32 constant REFUND_POSTOP_COST = 41000;

    uint192 ttl = 0;
    uint32 updateThreshold = 0;

    mapping(IERC20Metadata => TokenInfo) _tokenInfo;
    mapping(IERC20Metadata => Cache) _cache;

    Oracle public oracle = Oracle.CHAINLINK;
}

contract OracleHelper is AbstractStore, IOracleHelper {
    function getNativeToken() public view returns (TokenInfo memory) {
        return _tokenInfo[native];
    }

    function updatePrice(
        OracleQuery memory query,
        Oracle _oracle,
        bool force
    ) public returns (uint192) {
        Cache memory cache = _cache[query.token];
        uint256 cacheAge = block.timestamp - cache.timestamp;
        if (!force && cacheAge <= uint256(ttl)) {
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

        uint192 localPrice = uint192(price);
        uint192 _updateThreshold = uint192(updateThreshold);
        uint192 denominator = uint192(PRICE_DENOMINATOR);

        uint192 priceNewByOld = (localPrice * denominator) / cache.price;
        bool updateRequired = force ||
            priceNewByOld > denominator + _updateThreshold ||
            priceNewByOld < denominator - _updateThreshold;
        if (!updateRequired) {
            return cache.price;
        }

        _cache[query.token].price = localPrice;
        cache.timestamp = uint64(block.timestamp);
        _cache[query.token].timestamp = cache.timestamp;
        emit TokenPriceUpdated(address(query.token), localPrice, cache.price, cache.timestamp);
        return localPrice;
    }

    function getPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint8 decimals
    ) public view returns (uint256) {
        (
            uint80 roundId,
            int256 basePrice,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(baseFeed).latestRoundData();
        _requiresAnswerInRound(roundId, updatedAt, answeredInRound);
        (
            uint80 tRoundId,
            int256 tokenPrice,
            ,
            uint256 tUpdatedAt,
            uint80 tAnsweredInRound
        ) = AggregatorV3Interface(tokenFeed).latestRoundData();
        _requiresAnswerInRound(tRoundId, tUpdatedAt, tAnsweredInRound);
        _requiresPriceGreaterThanZero(basePrice, tokenPrice);
        return (uint256(decimals) * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint8 decimals
    ) public view returns (uint256) {
        (int256 basePrice, uint256 bTime) = ISupraConsumer(priceFeed).checkPrice(baseTicker);
        _requiresAnswerInRound(0, bTime, 1);
        (int256 tokenPrice, uint256 tTime) = ISupraConsumer(priceFeed).checkPrice(tokenTicker);
        _requiresAnswerInRound(0, tTime, 1);
        _requiresPriceGreaterThanZero(basePrice, tokenPrice);
        return (uint256(decimals) * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getPriceFromAPI3DAO(
        address baseProxy,
        address tokenProxy,
        uint8 decimals
    ) public view returns (uint256) {
        (int224 basePrice, uint32 bTime) = IAPI3Proxy(baseProxy).read();
        _requiresAnswerInRound(0, bTime, 1);
        (int224 tokenPrice, uint32 tTime) = IAPI3Proxy(tokenProxy).read();
        _requiresAnswerInRound(0, tTime, 1);
        _requiresPriceGreaterThanZero(basePrice, tokenPrice);
        uint224 price = (uint224(decimals) * uint224(basePrice)) / uint224(tokenPrice);
        return uint256(price);
    }

    function _requiresAnswerInRound(
        uint80 roundId,
        uint256 updatedAt,
        uint80 answeredInRound
    ) internal view {
        uint256 two_four_hours = block.timestamp - 60 * 60 * 24 * 2;
        if (updatedAt < two_four_hours || answeredInRound < roundId) revert StalePrice();
    }

    function _requiresPriceGreaterThanZero(int256 a, int256 b) internal pure {
        if (a <= 0 || b <= 0) revert PriceIsZeroOrLess(a, b);
    }

    function _requiresValidDecimalsForPair(
        OracleQuery memory self,
        uint8 a,
        uint8 b
    ) internal pure {
        if (a < 6 || b < 6) revert UnknownTokenPair(self.base, self.token);
    }

    function _setUpdateThresholdAndTTL(uint32 _threshold, uint192 _ttl) internal {
        if (_threshold > 1e6) revert UpdateThresholdTooHigh(_threshold);
        updateThreshold = _threshold;
        ttl = _ttl;
    }
}
