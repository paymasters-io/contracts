// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPaymaster} from "@matterlabs/zksync-contracts/l2/system-contracts/interfaces/IPaymaster.sol";
import {Transaction} from "@matterlabs/zksync-contracts/l2/system-contracts/libraries/TransactionHelper.sol";

interface IPaymasterDelegationV0 is IPaymaster {
    function delegate(Transaction calldata _transaction) external;
}
