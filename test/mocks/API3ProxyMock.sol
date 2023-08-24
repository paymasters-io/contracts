// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@paymasters-io/interfaces/oracles/IProxy.sol";

contract MockIProxy is Test, IProxy {
    int224 public value;

    constructor(int224 _value) {
        value = _value;
    }

    function read() external view override returns (int224, uint32) {
        return (value, 0);
    }

    function api3ServerV1() external pure override returns (address) {
        return address(0);
    }

    function testIgnoresMock() public {
        assertTrue(1 == 1, "mock not ignored");
    }
}
