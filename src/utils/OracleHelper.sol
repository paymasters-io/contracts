// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/interfaces/oracles/IProxy.sol";
import "@paymasters-io/interfaces/oracles/ISupraConsumer.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@paymasters-io/interfaces/oracles/IOracleHelper.sol";

/// utility functions for price oracle
contract OracleHelper is IOracleHelper {
    function getDerivedPrice(
        OracleQueryInput memory self,
        uint256 gasFee,
        Oracle oracle
    ) public view returns (uint256) {
        if (oracle == Oracle.SUPRAORACLE) {
            return getDerivedPriceFromSupra(self.baseProxyOrFeed, self.baseTicker, self.tokenTicker, gasFee);
        } else if (oracle == Oracle.CHAINLINK) {
            return getDerivedPriceFromChainlink(self.baseProxyOrFeed, self.tokenProxyOrFeed, gasFee);
        }
        return getDerivedPriceFromAPI3(self.baseProxyOrFeed, self.tokenProxyOrFeed, gasFee);
    }

    function getDerivedPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint256 gasFee
    ) public view returns (uint256) {
        (, int256 basePrice, , , ) = AggregatorV3Interface(baseFeed).latestRoundData();
        (, int256 tokenPrice, , , ) = AggregatorV3Interface(tokenFeed).latestRoundData();
        return (gasFee * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getDerivedPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint256 gasFee
    ) public view returns (uint256) {
        (int256 basePrice, ) = ISupraConsumer(priceFeed).checkPrice(baseTicker);
        (int256 tokenPrice, ) = ISupraConsumer(priceFeed).checkPrice(tokenTicker);
        return (gasFee * uint256(basePrice)) / uint256(tokenPrice);
    }

    function getDerivedPriceFromAPI3(
        address baseProxy,
        address tokenProxy,
        uint256 gasFee
    ) public view returns (uint256) {
        (int224 basePrice, ) = IProxy(baseProxy).read();
        (int224 tokenPrice, ) = IProxy(tokenProxy).read();
        return (gasFee * uint224(basePrice)) / uint224(tokenPrice);
    }
}
