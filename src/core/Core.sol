// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@paymasters-io/library/AccessControlHelper.sol";
import "@paymasters-io/library/SignatureValidationHelper.sol";
import "@paymasters-io/library/OracleHelper.sol";
import "@paymasters-io/library/Errors.sol";
import "@paymasters-io/security/Guard.sol";

/// @notice validation and access-control impl that can be reused in any EVM or zkEVM paymaster
abstract contract Core is Guard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using AccessControlHelper for AccessControlSchema;
    using SignatureValidationHelper for bytes;
    using OracleHelper for OracleQueryInput;

    address public vaa; // validation address
    mapping(address => bool) public isSibling;

    AccessControlSchema public accessControlSchema;
    SigConfig public signatureConf;

    struct TokenInfo {
        address proxyOrFeed;
        string ticker;
    }

    mapping(IERC20 => TokenInfo) public tokenToInfo;
    // debt mechanism is used to track the debt of a paymaster to (this).
    mapping(address => uint256) public siblingsToDebt;

    Oracle public defaultOracle = Oracle.API3;

    modifier isAuthorized() {
        if (msg.sender != vaa) revert UnAuthorized();
        _;
    }

    function setNodeSigners(address primarySigner, address secondarySigner, uint256 sigCount) external isAuthorized {
        if (sigCount > 2) revert InvalidConfig();
        signatureConf.verifyingSigner1 = primarySigner;
        signatureConf.verifyingSigner2 = secondarySigner;
        signatureConf.validNumOfSignatures = SigCount(sigCount);
    }

    function setSibling(address sibling, bool value) external isAuthorized {
        isSibling[sibling] = value;
    }

    function setAccessControlSchema(AccessControlSchema calldata schema) external isAuthorized {
        accessControlSchema = schema;
    }

    function setDefaultOracle(Oracle oracle) external isAuthorized {
        defaultOracle = oracle;
    }

    function previewAccess(address user) external view returns (bool) {
        return accessControlSchema.previewAccess(user);
    }

    // use the next two methods cautiously
    // do not use a ticker oracle with a proxy/feed or vice versa
    // paymasters-io handles this internally
    function addTokenTicker(IERC20 token, string memory ticker) external isAuthorized {
        tokenToInfo[token].ticker = ticker;
    }

    function addTokenProxyOrFeed(IERC20 token, address proxyOrFeed) external isAuthorized {
        tokenToInfo[token].proxyOrFeed = proxyOrFeed;
    }

    function withdraw() external nonReentrant whenNotPaused isAuthorized {
        uint256 balance = address(this).balance;
        msg.sender.call{value: balance}("");
    }

    function payDebt(address debtor) public payable whenNotPaused {
        siblingsToDebt[debtor] -= msg.value;
    }

    function _transferTokens(address from, IERC20 feeToken, uint256 amount) internal nonReentrant whenNotPaused {
        feeToken.safeTransferFrom(from, vaa, amount);
    }

    function _getPriceFromOracle(IERC20 feeToken, uint256 amount) internal view returns (uint256) {
        OracleQueryInput memory input = OracleQueryInput(
            tokenToInfo[IERC20(address(0x0))].proxyOrFeed,
            tokenToInfo[feeToken].proxyOrFeed,
            tokenToInfo[IERC20(address(0x0))].ticker,
            tokenToInfo[feeToken].ticker
        );

        return input.getDerivedPrice(amount, defaultOracle);
    }

    /// This method should not revert for any reason other than token transfer
    /// paymasterAndData[0:20] : address(sibling)  || address(this) 20 byte
    /// paymasterAndData[20:40] : IERC20(feeToken) 20byte
    /// paymasterAndData[40:72] : uint256(amount) 32byte
    /// paymasterAndData[72:104] : bytes32(hash) 32byte
    /// paymasterAndData[104:] : bytes(signatures) >64byte
    function _validate(bytes calldata paymasterAndData, address caller) internal virtual returns (bool success) {
        IERC20 feeToken = IERC20(address(bytes20(paymasterAndData[20:40])));
        if (tokenToInfo[feeToken].proxyOrFeed == address(0) || bytes(tokenToInfo[feeToken].ticker).length == 0) {
            revert FailedToValidatedOp();
        }

        // pre-calculated
        uint256 feeAmount = uint256(bytes32(paymasterAndData[40:72]));

        address sibling = address(bytes20(paymasterAndData[0:20]));
        // if sibling is not a delegate, then it must be (this)
        if (isSibling[sibling]) {
            _transferTokens(caller, feeToken, feeAmount);
            return true;
        } else if (sibling != address(this)) {
            revert FailedToValidatedOp();
        }

        SigConfig memory _signatureConf = signatureConf;
        SigCount expectedValidationStep = _signatureConf.validNumOfSignatures;
        bytes32 hash = keccak256(paymasterAndData[72:104]);
        bytes calldata signatures = paymasterAndData[104:];

        if (expectedValidationStep == SigCount.ONE) {
            if (_signatureConf.verifyingSigner1 == address(0) && _signatureConf.verifyingSigner2 == address(0)) {
                revert FailedToValidatedOp();
            }
            address signer = signatures.validateOneSignature(hash);
            success = (signer == _signatureConf.verifyingSigner1 || signer == _signatureConf.verifyingSigner2);
        } else if (expectedValidationStep == SigCount.TWO) {
            if (_signatureConf.verifyingSigner1 == address(0) || _signatureConf.verifyingSigner2 == address(0)) {
                revert FailedToValidatedOp();
            }
            (address primarySigner, address secondarySigner) = signatures.validateTwoSignatures(hash);
            success =
                (primarySigner == _signatureConf.verifyingSigner1 &&
                    secondarySigner == _signatureConf.verifyingSigner2) ||
                (primarySigner == _signatureConf.verifyingSigner2 &&
                    secondarySigner == _signatureConf.verifyingSigner1);
        }

        _transferTokens(caller, feeToken, feeAmount);
    }
}
