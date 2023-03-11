// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

error OperationFailed(bytes reason);

library HelperFuncs {
    /// @dev - internal function that handles transfer of ERC20 fee to fee receiver or VA
    /// @param from - the address of the transaction sender
    /// @param to - (optional) the address of fee receiver or VA
    /// @param amount - amount of tokens to be transferred to fee Receiver
    /// @param token - conreact address of the ERC20 token
    function handleTokenTransfer(
        address from,
        address to,
        uint256 amount,
        IERC20 token
    ) public {
        if (checkAllowance(from, token) < amount) revert OperationFailed("insufficient allowance");
        SafeERC20.safeTransferFrom(token, from, to, amount);
    }

    /// @dev - internal function that checks for token allowance
    /// @param txFrom - the address of the transaction sender
    /// @param token - contract address of the ERC20 token
    /// @return - The allowance (uint256) e.g 1000
    function checkAllowance(address txFrom, IERC20 token) public view returns (uint256) {
        uint256 providedAllowance = token.allowance(txFrom, address(this));
        return providedAllowance;
    }
}
