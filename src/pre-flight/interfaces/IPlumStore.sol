// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PaymasterMetadata} from "../library/AccessLibrary.sol";

interface IPlumStore {
    event NewPaymaster(address paymaster, bytes metadata, address owner);

    function save(
        address owner,
        address contractAddress,
        bytes memory metadata
    ) external;

    function save(address contractAddress, bytes calldata metadata) external;

    function update(address contractAddress, bytes memory metadata) external;

    function remove(address contractAddress) external;

    function get(address owner) external view returns (PaymasterMetadata[] memory);

    function getAll() external view returns (PaymasterMetadata[] memory);
}
