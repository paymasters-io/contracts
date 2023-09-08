// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@paymasters-io/interfaces/oracles/ISupraConsumer.sol";

contract MockISupraConsumer is Test, ISupraConsumer {
    int256 public price;
    int256 public priceToken;

    constructor(int256 _price, int256 _priceToken) {
        price = _price;
        priceToken = _priceToken;
    }

    function getSvalues(
        uint64[] memory _pairIndexes
    ) external view override returns (bytes32[] memory, bool[] memory) {
        return (new bytes32[](0), new bool[](0));
    }

    function getSvalue(uint64 _pairIndex) external view override returns (bytes32, bool) {
        return (bytes32(0), true);
    }

    function testIgnoresMock() public {
        assertTrue(1 == 1, "mock not ignored");
    }
}
