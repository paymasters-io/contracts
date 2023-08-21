// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockAggregatorV3Interface is Test {
    int256 public price;

    constructor(int256 _price) {
        price = _price;
    }

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, price, 0, 0, 0);
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function description() public pure returns (string memory) {
        return "";
    }

    function version() public pure returns (uint256) {
        return 0;
    }

    function testIgnoresMock() public {
        assertTrue(1 == 1, "mock not ignored");
    }
}
