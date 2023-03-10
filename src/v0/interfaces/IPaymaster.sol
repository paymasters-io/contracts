// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPaymaster} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";

interface IxPaymasterV0 is IPaymaster {
    function satisfy(address user) external payable returns (bool status);
}
