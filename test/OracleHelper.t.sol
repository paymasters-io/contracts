// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@paymasters-io/library/OracleHelper.sol";
import "mocks/V3AggregatorMock.sol";
import "mocks/SupraConsumerMock.sol";
import "mocks/RedstoneConsumerNumericBaseMock.sol";
import "mocks/API3ProxyMock.sol";

contract TestOracleHelper is Test {
    using OracleHelper for OracleQueryInput;

    OracleQueryInput input;
    uint256 gasFee = 100;

    function setUp() public {
        input = OracleQueryInput({
            baseProxyOrFeed: address(new MockAggregatorV3Interface(100)),
            tokenProxyOrFeed: address(new MockAggregatorV3Interface(200)),
            baseTicker: "eth",
            tokenTicker: "usdc"
        });
    }

    function testGetDerivedPriceFromChainlink() public {
        uint256 expectedPrice = 50;
        uint256 price = input.getDerivedPrice(gasFee, Oracle.CHAINLINK);

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromAPI3() public {
        input.baseProxyOrFeed = address(new MockIProxy(100));
        input.tokenProxyOrFeed = address(new MockIProxy(200));
        uint256 expectedPrice = 50;
        uint256 price = input.getDerivedPrice(gasFee, Oracle.API3);

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromSupra() public {
        input.baseProxyOrFeed = address(new MockISupraConsumer(50, 100));
        uint256 expectedPrice = 50;
        uint256 price = input.getDerivedPrice(gasFee, Oracle.SUPRAORACLE);

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromRedstone() public {
        input.baseProxyOrFeed = address(new MockIRedstoneConsumerNumericBase(100));
        // uint256 expectedPrice = 50;
        vm.expectRevert("redstone disabled");
        input.getDerivedPrice(gasFee, Oracle.REDSTONE);

        // assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromChainlinkInternal() public {
        uint256 expectedPrice = 50;
        uint256 price = OracleHelper.getDerivedPriceFromChainlink(
            input.baseProxyOrFeed,
            input.tokenProxyOrFeed,
            gasFee
        );

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromAPI3Internal() public {
        input.baseProxyOrFeed = address(new MockIProxy(100));
        input.tokenProxyOrFeed = address(new MockIProxy(200));
        uint256 expectedPrice = 50;
        uint256 price = OracleHelper.getDerivedPriceFromAPI3(input.baseProxyOrFeed, input.tokenProxyOrFeed, gasFee);

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromSupraInternal() public {
        input.baseProxyOrFeed = address(new MockISupraConsumer(50, 100));
        uint256 expectedPrice = 50;
        uint256 price = OracleHelper.getDerivedPriceFromSupra(
            input.baseProxyOrFeed,
            input.baseTicker,
            input.tokenTicker,
            gasFee
        );

        assertEq(price, expectedPrice, "Price should match");
    }

    function testGetDerivedPriceFromRedstoneInternal() public {
        input.baseProxyOrFeed = address(new MockIRedstoneConsumerNumericBase(100));

        uint256 expectedPrice = 100;
        uint256 price = OracleHelper.getDerivedPriceFromRedstone(
            input.baseProxyOrFeed,
            input.baseTicker,
            input.tokenTicker,
            gasFee
        );
        assertEq(price, expectedPrice, "Price should match");
    }
}
