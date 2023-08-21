// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@paymasters-io/library/AccessControlHelper.sol";
import "@paymasters-io/interfaces/IDelegator.sol";

interface ICore is IDelegator {
    function setNodeSigners(address primarySigner, address secondarySigner, uint256 sigCount) external;

    function setDelegator(address delegator, bool value) external;

    function setAccessControlSchema(AccessControlSchema calldata schema) external;

    function setVAA(address _vaa) external;

    function setMaxNonce(uint256 _maxNonce) external;

    function previewAccess(address user) external view returns (bool);

    function withdraw() external;

    function payDebt(address debtor) external payable;
}
