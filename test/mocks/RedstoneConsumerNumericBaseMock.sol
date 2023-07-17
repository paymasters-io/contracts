// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "@paymasters-io/interfaces/IRedstoneConsumerNumericBase.sol";

contract MockIRedstoneConsumerNumericBase is Test, IRedstoneConsumerNumericBase {
    uint256 public price;

    constructor(uint256 _price) {
        price = _price;
    }

    function getOracleNumericValueFromTxMsg(bytes32 dataFeedId) external view override returns (uint256) {
        (dataFeedId);
        return price;
    }

    function getOracleNumericValuesFromTxMsg(
        bytes32[] memory dataFeedIds
    ) external view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](dataFeedIds.length);
        for (uint256 i = 0; i < dataFeedIds.length; i++) {
            prices[i] = price;
        }
        return prices;
    }

    function testIgnoresMock() public {
        assertTrue(1 == 1, "mock not ignored");
    }
}
