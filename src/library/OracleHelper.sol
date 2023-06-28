// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@paymasters-io/interfaces/IProxy.sol";
import "@paymasters-io/interfaces/ISupraConsumer.sol";
import "@paymasters-io/interfaces/IRedstoneConsumerNumericBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

enum Oracle {
    CHAINLINK,
    REDSTONE,
    SUPRAORACLE,
    API3
}

struct OracleQueryInput {
    address baseProxyOrFeed;
    address tokenProxyOrFeed;
    // feeds/tickers are of type string for supra oracle
    string baseTicker;
    string tokenTicker;
}

/// utility functions for price oracle
library OracleHelper {
    function getDerivedPrice(
        OracleQueryInput memory self,
        uint256 gasFee,
        Oracle oracle
    ) public view returns (uint256) {
        if (oracle == Oracle.REDSTONE) {
            return getDerivedPriceFromRedstone(self.baseProxyOrFeed, self.baseTicker, self.tokenTicker, gasFee);
        } else if (oracle == Oracle.SUPRAORACLE) {
            return getDerivedPriceFromSupra(self.baseProxyOrFeed, self.baseTicker, self.tokenTicker, gasFee);
        } else if (oracle == Oracle.CHAINLINK) {
            return getDerivedPriceFromChainlink(self.baseProxyOrFeed, self.tokenProxyOrFeed, gasFee);
        } else if (oracle == Oracle.API3) {
            return getDerivedPriceFromAPI3(self.baseProxyOrFeed, self.tokenProxyOrFeed, gasFee);
        } else {
            revert("invalid oracle");
        }
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

    function getDerivedPriceFromRedstone(
        address priceFeedContract,
        string memory baseTicker,
        string memory tokenTicker,
        uint256 gasFee
    ) public view returns (uint256) {
        bytes32[] memory dataFeedIds = new bytes32[](2);
        dataFeedIds[0] = bytes32(bytes(baseTicker));
        dataFeedIds[1] = bytes32(bytes(tokenTicker));
        uint256[] memory prices = IRedstoneConsumerNumericBase(priceFeedContract).getOracleNumericValuesFromTxMsg(
            dataFeedIds
        );
        uint256 basePrice = prices[0];
        uint256 tokenPrice = prices[1];
        return (gasFee * basePrice) / tokenPrice;
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
