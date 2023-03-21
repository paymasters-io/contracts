// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PaymasterMeta} from "./utils/Structs.sol";
import "./utils/Modifiers.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AggregatorV0 is ISmod, Ownable {
    PaymasterMeta[] private paymasters;
    mapping(address => uint256[]) private ownerToPaymasters;

    event NewPaymster(address paymaster, bytes metadata, address owner);

    function save(
        address owner,
        address paymasterAddr,
        bytes memory metadata
    ) public onlyOwner {
        _save(owner, paymasterAddr, metadata);
    }

    function save(address owner, bytes memory metadata) external onlyPaymasters(msg.sender) {
        _save(owner, msg.sender, metadata);
    }

    function _save(
        address owner,
        address paymasterAddr,
        bytes memory metadata
    ) internal {
        ownerToPaymasters[owner].push(paymasters.length);
        paymasters.push(PaymasterMeta({contractAddress: paymasterAddr, metadata: metadata}));
        emit NewPaymster(paymasterAddr, metadata, owner);
    }

    function update(address paymasterAddr, bytes memory metadata) external {
        uint256[] memory ownedPaymasters = ownerToPaymasters[msg.sender];
        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            if (paymasters[ownedPaymasters[i]].contractAddress == paymasterAddr) {
                paymasters[ownedPaymasters[i]].metadata = metadata;
            }
        }
    }

    function remove(address paymasterAddr) external {
        uint256[] memory ownedPaymasters = ownerToPaymasters[msg.sender];
        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            if (paymasters[ownedPaymasters[i]].contractAddress == paymasterAddr) {
                paymasters[ownedPaymasters[i]] = paymasters[paymasters.length - 1];
                paymasters.pop();
            }
        }
    }

    function get(address owner) external view returns (PaymasterMeta[] memory) {
        uint256[] memory ownedPaymasters = ownerToPaymasters[owner];
        PaymasterMeta[] memory all = new PaymasterMeta[](ownedPaymasters.length);

        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            all[i] = paymasters[ownedPaymasters[i]];
        }

        return all;
    }

    function getAll() external view returns (PaymasterMeta[] memory) {
        return paymasters;
    }
}
