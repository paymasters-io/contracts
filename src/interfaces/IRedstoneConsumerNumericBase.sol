// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRedstoneConsumerNumericBase {
    function getOracleNumericValueFromTxMsg(bytes32 dataFeedId) external view returns (uint256);

    /**
     * @dev This function can be used in a consumer contract to securely extract several
     * numeric oracle values for a given array of data feed ids. Security is achieved by
     * signatures verification, timestamp validation, and aggregating values
     * from different authorised signers into a single numeric value. If any of the
     * required conditions do not match, the function will revert.
     * Note! This function expects that tx calldata contains redstone payload in the end
     * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
     * @param dataFeedIds An array of unique data feed identifiers
     * @return An array of the extracted and verified oracle values in the same order
     * as they are requested in the dataFeedIds array
     */
    function getOracleNumericValuesFromTxMsg(bytes32[] memory dataFeedIds) external view returns (uint256[] memory);
}
