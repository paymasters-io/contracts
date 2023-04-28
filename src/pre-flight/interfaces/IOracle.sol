// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracle {
    function getDerivedPrice(
        address _base,
        address _quote,
        int256 amount
    ) external view returns (int256);

    function getDerivedPrice(address _base, int256 amount) external view returns (int256);
}
