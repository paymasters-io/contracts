// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@paymasters-io/interfaces/oracles/IProxy.sol";
import "@paymasters-io/interfaces/oracles/ISupraConsumer.sol";
import "@paymasters-io/interfaces/oracles/IOracleHelper.sol";

/// utility functions for price oracle
contract OracleHelper is IOracleHelper {
    Oracle public oracle = Oracle.CHAINLINK;
    mapping(IERC20Metadata => TokenInfo) tokenInfo;
    mapping(IERC20Metadata => Cache) cache;

    function getNativeToken() public view returns (TokenInfo memory) {
        return tokenInfo[IERC20Metadata(address(0x0))];
    }

    function updatePrice(OracleQuery memory self, Oracle _oracle) public {
        TokenInfo memory base = tokenInfo[self.base];
        TokenInfo memory token = tokenInfo[self.token];
        _requiresValidDecimalsForPair(self, base.decimals, token.decimals);
        // TODO: implement caching logic

        uint256 price;
        if (_oracle == Oracle.CHAINLINK) {
            price = getPriceFromChainlink(base.proxyOrFeed, token.proxyOrFeed, token.decimals);
        } else if (_oracle == Oracle.SUPRA) {
            price = getPriceFromSupra(base.proxyOrFeed, base.ticker, token.ticker, token.decimals);
            return;
        } else {
            price = getPriceFromAPI3DAO(base.proxyOrFeed, token.proxyOrFeed, token.decimals);
        }

        emit TokenPriceUpdated(address(self.token), 0, 0, 0);
    }

    function getPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint256 decimals
    ) public view returns (uint256) {
        (, int256 basePrice, , , ) = AggregatorV3Interface(baseFeed).latestRoundData();
        (, int256 tokenPrice, , , ) = AggregatorV3Interface(tokenFeed).latestRoundData();
        _requiresPrizeGreaterThanZero(uint(basePrice), uint(tokenPrice));
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
        _requiresPrizeGreaterThanZero(uint(basePrice), uint(tokenPrice));
        return (decimals * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getPriceFromAPI3DAO(
        address baseProxy,
        address tokenProxy,
        uint256 decimals
    ) public view returns (uint256) {
        (int224 basePrice, ) = IProxy(baseProxy).read();
        (int224 tokenPrice, ) = IProxy(tokenProxy).read();
        _requiresPrizeGreaterThanZero(uint224(basePrice), uint224(tokenPrice));
        return (decimals * uint224(basePrice)) / uint224(tokenPrice);
    }

    function _requiresPrizeGreaterThanZero(uint256 a, uint256 b) internal pure {
        if (a <= 0 || b <= 0) revert PriceIsZeroOrLess(a, b);
    }

    function _requiresValidDecimalsForPair(OracleQuery memory self, uint256 a, uint256 b) internal pure {
        if (a < 6 || b < 6) revert UnknownTokenPair(self.base, self.token);
    }
}
