// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IAccessChecker {
    function previewSatisfy(address user) external payable returns (bool);

    function previewTrigger(
        address txTo,
        uint256 txValue,
        bytes memory msgData
    ) external payable returns (bool);
}
