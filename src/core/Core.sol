// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@paymasters-io/library/AccessControlHelper.sol";
import "@paymasters-io/library/SignatureValidationHelper.sol";
import "@paymasters-io/library/PaymasterOperationsHelper.sol";
import "@paymasters-io/library/OracleHelper.sol";
import "@paymasters-io/library/Errors.sol";
import "@paymasters-io/security/Guard.sol";

abstract contract Core is Guard {
    using ECDSA for bytes32;
    using OracleHelper for OracleQueryInput;
    using AccessControlHelper for AccessControlSchema;
    using PaymasterOperationsHelper for *;

    address public vaa; // validation address
    address[] public siblings;

    AccessControlSchema public accessControlSchema;
    SigConfig public signatureConf;

    // saving the (address && strings) together to utilize a single mapping
    // but consuming more gas
    mapping(IERC20 => bytes) public tokenToProxyFeedOrTicker;
    mapping(address => uint256) public siblingsToDebt;

    Oracle public defaultOracle = Oracle.API3;

    modifier isAuthorized() {
        if (msg.sender != vaa) revert UnAuthorized();
        _;
    }

    function setNodeSigners(address primarySigner, address secondarySigner, uint8 sigCount) external isAuthorized {
        if (sigCount > 2) revert InvalidConfig();
        signatureConf.verifyingSigner1 = primarySigner;
        signatureConf.verifyingSigner2 = secondarySigner;
        signatureConf.validNumOfSignatures = SigCount(sigCount);
    }

    function addSibling(address sibling) external isAuthorized {
        siblings.push(sibling);
    }

    function removeSibling(address sibling) external isAuthorized {
        for (uint256 i = 0; i < siblings.length; i++) {
            if (siblings[i] == sibling) {
                siblings[i] = siblings[siblings.length - 1];
                siblings.pop();
                break;
            }
        }
    }

    function setAccessControlSchema(AccessControlSchema calldata schema) external isAuthorized {
        accessControlSchema = schema;
    }

    function setDefaultOracle(Oracle oracle) external isAuthorized {
        defaultOracle = oracle;
    }

    function previewAccess(address user) public view returns (bool) {
        return accessControlSchema.previewAccess(user);
    }

    // use the next two methods cautiously
    // do not use a ticker oracle with a proxy/feed or vice versa
    // paymasters-io handles this internally
    function addTokenTicker(IERC20 token, string memory pair) external isAuthorized {
        tokenToProxyFeedOrTicker[token] = bytes(pair);
    }

    function addTokenProxyOrFeed(IERC20 token, address proxyOrFeed) external isAuthorized {
        tokenToProxyFeedOrTicker[token] = abi.encodePacked(proxyOrFeed);
    }

    function withdraw() external isAuthorized {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function payDebt(address debtor) public payable {
        siblingsToDebt[debtor] -= msg.value;
    }

    function _validate(bytes calldata paymasterAndData, address caller) internal virtual;

    function _post(bytes calldata context) internal virtual;
}
