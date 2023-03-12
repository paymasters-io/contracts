// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@redstone/contracts/data-services/AvalancheDataServiceConsumerBase.sol";

contract PriceFeedConsumer is AvalancheDataServiceConsumerBase {
    bytes32 private _quoteFeed;

    constructor(bytes32 quoteFeed) {
        _quoteFeed = quoteFeed;
    }

    // public view method accepting custom quote
    function getDerivedPrice(
        bytes32 _base,
        bytes32 _quote,
        uint256 amount
    ) public view returns (uint256) {
        return _getDerivedPrice(_base, _quote, amount);
    }

    // actual derivation method using the immutable quote
    function getDerivedPrice(bytes32 _base, uint256 amount) external view returns (uint256) {
        return _getDerivedPrice(_base, _quoteFeed, amount);
    }

    // internal method that does the actual derivation
    function _getDerivedPrice(
        bytes32 _base,
        bytes32 _quote,
        uint256 amount
    ) internal view returns (uint256) {
        bytes32[] memory feeds;
        feeds[0] = _base;
        feeds[1] = _quote;
        uint256[] memory result = getLatestPricesForManyAssets(feeds);
        return (result[0] * amount) / result[1];
    }

    function getQuotePriceFeed() external view returns (bytes32) {
        return _quoteFeed;
    }

    function getUniqueSignersThreshold() public pure returns (uint8) {
        return 3;
    }

    function getLatestFeedPrice() public view returns (uint256) {
        return getOracleNumericValueFromTxMsg(_quoteFeed);
    }

    function getLatestPricesForManyAssets(bytes32[] memory dataFeedIds)
        public
        view
        returns (uint256[] memory)
    {
        return getOracleNumericValuesFromTxMsg(dataFeedIds);
    }
}
