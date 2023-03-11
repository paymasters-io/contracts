// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAccessChecker {
    function satisfy(address user) external payable returns (bool status);
}
