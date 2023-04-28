// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./AccessLibrary.sol";

/// @title Paymasters Access Control Library
/// @author peter Anyaogu
/// @notice used for access control logic in the Paymasters contracts
library AccessControl {
    /// @dev restricts paymaster to users whose nonce is under specific value.
    /// @param value - the maximum nonce accepted by the paymaster contract
    /// @param current - the nonce passed with the transaction
    /// @return  - true / false
    function useMaxNonce(uint256 value, uint256 current) public pure returns (bool) {
        return current <= value;
    }

    /// @dev restricts paymaster to users who are holding a specific amount of ERC20 token.
    /// @param erc20Contract - the ERC20 token contract address
    /// @param value - the the amount of tokens the user is expected to hold.
    /// @param from - the address of the tx sender
    /// @return  - true / false
    function useERC20Gate(
        address erc20Contract,
        uint256 value,
        address from
    ) public view returns (bool) {
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", from);
        return _externalCall(payload, erc20Contract, value);
    }

    /// @dev restricts paymaster to users who are holding at an NFT.
    /// @param nftContract - the NFT contract address
    /// @param from - the address of the tx sender
    /// @return  - true / false
    function useNFTGate(address nftContract, address from) public view returns (bool) {
        // payload only support erc721 only
        bytes memory payload = abi.encodeWithSignature("balanceOf(address)", from);
        return _externalCall(payload, nftContract, 1);
    }

    /// @dev restricts paymaster to users who are interacting with specific contracts.
    /// @param to - the destination contract address for the transaction.
    /// @return  - true / false
    function useStrictDestination(AccessLibrary.AccessControlSchema storage self, address to)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.strictDestinations.length; i++) {
            if (to == self.strictDestinations[i]) return true;
        }
        return false;
    }

    /// @notice function for making the actual external call
    /// @dev returns the value as-is without comparison
    /// @param _payload - the the encoded function signature in bytes
    /// @param _to - the contract address to send external call.
    /// @return - (uint256)
    function externalCall(bytes memory _payload, address _to) public view returns (uint256) {
        (bool success, bytes memory returnData) = address(_to).staticcall(_payload);
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        revert("external call failed");
    }

    /// @dev function for handling external calls
    /// @dev returned value will be compared against the provided value
    /// @param _payload - the the encoded function signature in bytes
    /// @param _to - the contract address to perform external call.
    /// @param _value - value to be compared against the return value from the external call.
    /// @return  - true / false
    function _externalCall(
        bytes memory _payload,
        address _to,
        uint256 _value
    ) private view returns (bool) {
        return externalCall(_payload, _to) >= _value ? true : false;
    }
}
