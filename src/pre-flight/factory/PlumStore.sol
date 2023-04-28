// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {PaymasterMetadata} from "../library/AccessLibrary.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessChecker} from "../interfaces/IAccessChecker.sol";

contract PlumStore is Ownable {
    PaymasterMetadata[] private paymasters;
    mapping(address => uint256[]) private ownerToPaymasters;
    address private _greggsFactory;

    event NewPaymaster(address paymaster, bytes metadata, address owner);

    function save(
        address owner,
        address contractAddress,
        bytes calldata metadata
    ) public {
        require(msg.sender == _greggsFactory, "only updated from source");
        _save(owner, contractAddress, metadata);
    }

    function save(address contractAddress, bytes calldata metadata) public {
        _save(msg.sender, contractAddress, metadata);
    }

    function _save(
        address owner,
        address contractAddress,
        bytes memory metadata
    ) internal {
        ownerToPaymasters[owner].push(paymasters.length);
        paymasters.push(PaymasterMetadata({contractAddress: contractAddress, metadata: metadata}));
        emit NewPaymaster(contractAddress, metadata, owner);
    }

    function update(address contractAddress, bytes memory metadata) external {
        uint256[] memory ownedPaymasters = ownerToPaymasters[msg.sender];
        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            if (paymasters[ownedPaymasters[i]].contractAddress == contractAddress) {
                paymasters[ownedPaymasters[i]].metadata = metadata;
            }
        }
    }

    function remove(address contractAddress) external {
        uint256[] memory ownedPaymasters = ownerToPaymasters[msg.sender];
        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            if (paymasters[ownedPaymasters[i]].contractAddress == contractAddress) {
                paymasters[ownedPaymasters[i]] = paymasters[paymasters.length - 1];
                paymasters.pop();
            }
        }
    }

    function get(address owner) external view returns (PaymasterMetadata[] memory) {
        uint256[] memory ownedPaymasters = ownerToPaymasters[owner];
        PaymasterMetadata[] memory all = new PaymasterMetadata[](ownedPaymasters.length);

        for (uint256 i = 0; i < ownedPaymasters.length; i++) {
            all[i] = paymasters[ownedPaymasters[i]];
        }

        return all;
    }

    function getAll() external view returns (PaymasterMetadata[] memory) {
        return paymasters;
    }

    function setSource(address factory) public onlyOwner {
        _greggsFactory = factory;
    }
}
