// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

struct PaymasterMeta {
    address contractAddress; // the contract address of a paymaster contract
    bytes metadata; // the off-chain metadata of the paymaster contract
}

struct AccessControlSchema {
    uint256 maxNonce; // the accepted user nonce. upper boundary
    uint256 ERC20GateValue; // the amount of tokens required
    address validationAddress; // the address of the fee receiver
    address ERC20GateContract; // the token gating contract address (ERC20)
    address NFTGateContract; // the token gating contract address (ERC721) note! ERC1155 is not supported
}

struct AccessControlRules {
    bool useMaxNonce; // rule for activation nonce checking
    bool useERC20Gate; // rule for activation token holding check
    bool useNFTGate; // rule for activating nft holding check
    bool useTriggers; // rule for activating trigger plugins
}

struct TriggerSchema {
    uint256 minMsgValue; // the minimum value expected to be passed with the transaction
    address[] strictDestinations; // the list of allowed destination contracts
    bytes4[] calldataSelectors; // the functions selectors required from a transaction msg.data
    mapping(bytes4 => uint256[2]) calldataMinParams; // the input params expected from the calldata
}

struct TriggerRules {
    bool useSelector; // activates the checking of calldata function selector
    bool useSelectorParams; // activates the checking of calldata function params
    bool useStrictDestination; // rule for activating destination contract check
    bool useMsgValue; // activates the checking of value sent with the transaction
}

struct ApprovalBasedFlow {
    uint256 l2FeeAmount; // the amount of tokens to be charged as fee
    bool useOracleQuotes; // use chainlink oracles to get token equivalent of actual gas fee in usd
    address priceFeed; // the price feed to be used in the oracle request
    IERC20 l2FeeToken; // the ERC20 token to be used a gas fee token in the approval Based flow
}

struct RebateHandler {
    uint8 rebatePercentage; // the percentage of tx.value to be calculated for rebates
    uint128 maxNumberOfRebates; //maximum number of times a user can receive rebates in a lifetime.
    uint256 rebateTrigger; // the tx value lower boundary that can trigger rebates
    uint256 maxRebateAmount; // maximum amount of rebates a user can receive. set to uint256 max if not checked.
    address dispatcher; // the address to transfer the rebates from. can be set to validation address if need be
    IERC20 rebateToken; // the token contract address to be used for rebates
}
