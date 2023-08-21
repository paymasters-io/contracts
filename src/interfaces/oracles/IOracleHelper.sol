enum Oracle {
    CHAINLINK,
    SUPRAORACLE,
    API3
}

struct OracleQueryInput {
    address baseProxyOrFeed;
    address tokenProxyOrFeed;
    string baseTicker;
    string tokenTicker;
}

interface IOracleHelper {
    function getDerivedPrice(
        OracleQueryInput memory self,
        uint256 gasFee,
        Oracle oracle
    ) external view returns (uint256);

    function getDerivedPriceFromChainlink(
        address baseFeed,
        address tokenFeed,
        uint256 gasFee
    ) external view returns (uint256);

    function getDerivedPriceFromSupra(
        address priceFeed,
        string memory baseTicker,
        string memory tokenTicker,
        uint256 gasFee
    ) external view returns (uint256);

    function getDerivedPriceFromAPI3(
        address baseProxy,
        address tokenProxy,
        uint256 gasFee
    ) external view returns (uint256);
}
