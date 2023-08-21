// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@paymasters-io/interfaces/ISupraConsumer.sol";

contract MockISupraConsumer is Test, ISupraConsumer {
    int256 public price;
    int256 public priceToken;

    constructor(int256 _price, int256 _priceToken) {
        price = _price;
        priceToken = _priceToken;
    }

    function checkPrice(string memory marketPair) external view override returns (int256, uint256) {
        (marketPair);
        if (keccak256(bytes(marketPair)) == keccak256(bytes("eth"))) {
            return (price, 0);
        }
        return (priceToken, 0);
    }

    function testIgnoresMock() public {
        assertTrue(1 == 1, "mock not ignored");
    }
}
