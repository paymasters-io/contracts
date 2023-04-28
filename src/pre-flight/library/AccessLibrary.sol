// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

// paymaster identifier
struct PaymasterMetadata {
    address contractAddress; // the contract address of a paymaster contract
    bytes metadata; // the off-chain metadata of the paymaster contract
}

library AccessLibrary {
    // access control specification
    struct AccessControlRules {
        bool useMaxNonce; // rule for activation nonce checking
        bool useERC20Gate; // rule for activation token holding check
        bool useNFTGate; // rule for activating nft holding check
        bool useStrictDestination; // rule for activating destination contract check
    }

    // access control implementation
    struct AccessControlSchema {
        uint128 maxNonce; // the accepted user nonce. upper boundary
        uint128 ERC20GateValue; // the amount of tokens required
        address ERC20GateContract; // the token gating contract address (ERC20)
        address NFTGateContract; // the token gating contract address (ERC721) note! ERC1155 is not supported
        address validationAddress; // the address of the fee receiver
        address[] strictDestinations; // the list of allowed destination contracts
    }

    struct ApprovalBasedFlow {
        uint256 l2FeeAmount; // the amount of tokens to be charged as fee
        bool useOracleQuotes; // use chainlink oracles to get token equivalent of actual gas fee in usd
        address priceFeed; // the price feed to be used in the oracle request
        IERC20 l2FeeToken; // the ERC20 token to be used a gas fee token in the approval Based flow
    }

    /**
     * compares two strings
     * @param a - string A
     * @param b - String B
     */
    function compare(bytes memory a, bytes memory b) public pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    /**
     * updates the value of the access validation logic in the schema
     * @param self - intrinsic storage representation
     * @param schema - the schema to be updated (string representation)
     * @param data - value to be set for the schema
     */
    function updateSchema(
        AccessControlSchema storage self,
        bytes calldata schema,
        bytes calldata data
    ) public {
        if (compare(schema, "maxNonce")) {
            self.maxNonce = abi.decode(data, (uint128));
        }
        if (compare(schema, "ERC20GateValue")) {
            self.ERC20GateValue = abi.decode(data, (uint128));
        }
        if (compare(schema, "ERC20GateContract")) {
            self.ERC20GateContract = abi.decode(data, (address));
        }
        if (compare(schema, "NFTGateContract")) {
            self.NFTGateContract = abi.decode(data, (address));
        }
    }

    /**
     * toggles the rules (enables/disables) it based on the provided value
     * @param self - intrinsic reference to storage
     * @param rule - the rule to be updated (string representation)
     * @param value - value to be set for the rule
     */
    function updateRules(
        AccessControlRules storage self,
        bytes calldata rule,
        bool value
    ) public {
        if (compare(rule, "useMaxNonce")) {
            self.useMaxNonce = value;
        }
        if (compare(rule, "useERC20Gate")) {
            self.useERC20Gate = value;
        }
        if (compare(rule, "useNFTGate")) {
            self.useNFTGate = value;
        }
        if (compare(rule, "useStrictDestination")) {
            self.useStrictDestination = value;
        }
    }
}
