// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library PaymasterOperationsHelper {
    function staticCall(bytes calldata _payload, address _to) public view returns (uint256) {
        (bool success, bytes memory returnData) = _to.staticcall(_payload);
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        revert("staticcall operation failed");
    }

    function handleTokenTransfer(address from, address to, uint256 amount, IERC20 token) public {
        SafeERC20.safeTransferFrom(token, from, to, amount);
    }

    function checkAllowance(address txFrom, IERC20 token) public view returns (uint256) {
        uint256 providedAllowance = token.allowance(txFrom, address(this));
        return providedAllowance;
    }

    function isDelegate(address[] memory self, address sibling) public pure returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (sibling == self[i]) return true;
        }
        return false;
    }

    function previewDelegate(address[] storage siblings, address sibling) public pure returns (bool truthy) {
        truthy = true; // true & true = true, true & false = false, false & false = false.
        truthy = truthy && isDelegate(siblings, sibling);
    }
}
