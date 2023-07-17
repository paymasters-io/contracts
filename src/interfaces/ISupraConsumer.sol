// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISupraConsumer {
    function checkPrice(string memory marketPair) external view returns (int256 price, uint256 timestamp);
}
