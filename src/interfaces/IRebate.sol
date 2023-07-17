// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRebate {
    function rebate(address caller, uint256 value, uint256 refundValue, bytes calldata _context) external;
}
