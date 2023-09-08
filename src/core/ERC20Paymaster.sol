// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// openzeppelin
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// eth-infinitsm
import "@aa/contracts/core/BasePaymaster.sol";
import "@aa/contracts/core/Helpers.sol";
import "@aa/contracts/interfaces/UserOperation.sol";
import "@aa/contracts/interfaces/IEntryPoint.sol";
// paymasters.io
import "@paymasters-io/utils/OracleHelper.sol";
import "@paymasters-io/interfaces/IERC20Paymaster.sol";

/// @notice Adapted from eth-infinitism 'TokenPaymaster' and pimlico 'ERC20Paymaster'
contract ERC20Paymaster is BasePaymaster, OracleHelper, IERC20Paymaster {
    using SafeERC20 for IERC20Metadata;

    constructor(
        IEntryPoint _entryPoint,
        TokenInfo memory _nativeTokenInfo,
        uint192 _ttl,
        uint32 _updateThreshold,
        address _owner
    ) BasePaymaster(_entryPoint) Ownable(_owner) {
        _tokenInfo[NATIVE] = _nativeTokenInfo;
        _setUpdateThresholdAndTTL(_updateThreshold, _ttl);
    }

    function setOracle(Oracle _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleChanged(_oracle);
    }

    function addToken(IERC20Metadata token, TokenInfo memory tokenInfo) external onlyOwner {
        uint256 markup = uint256(tokenInfo.priceMarkup);
        if (markup > 2 * PRICE_DENOMINATOR || markup < PRICE_DENOMINATOR)
            revert PriceMarkupOutOfBounds(markup, PRICE_DENOMINATOR);
        tokenInfo.decimals = token.decimals();
        _tokenInfo[token] = tokenInfo;
        emit TokenAdded(address(token), tokenInfo.feed, markup, tokenInfo.priceMaxAge);
    }

    function removeToken(IERC20Metadata token) external onlyOwner {
        delete _tokenInfo[token];
        emit TokenRemoved(address(token));
    }

    function withdraw(IERC20Metadata token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function _validateToken(IERC20Metadata token) internal view {
        if (token == IERC20Metadata(address(0x0)) || _tokenInfo[token].feed == address(0x0)) {
            revert TokenNotSupported(address(token));
        }
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationResult) {
        unchecked {
            bytes calldata paymasterAndData = userOp.paymasterAndData;
            if (paymasterAndData.length - 20 != 20) revert TokenNotSpecified();
            IERC20Metadata token = IERC20Metadata(address(bytes20(paymasterAndData[20:])));

            _validateToken(token);

            TokenInfo memory tokenInfo = _tokenInfo[token];
            Cache memory cache = _cache[token];

            uint256 preChargeNative = requiredPreFund +
                (uint256(REFUND_POSTOP_COST) * userOp.maxFeePerGas);
            uint256 cachedPriceWithMarkup = (uint256(cache.price) * PRICE_DENOMINATOR) /
                uint256(tokenInfo.priceMarkup);
            uint256 tokenAmount = (preChargeNative * PRICE_DENOMINATOR) / cachedPriceWithMarkup;
            // slither-disable-next-line arbitrary-send-erc20
            token.safeTransferFrom(userOp.sender, address(this), tokenAmount);

            context = abi.encode(
                tokenAmount,
                userOp.maxFeePerGas,
                userOp.maxPriorityFeePerGas,
                userOp.sender,
                address(token)
            );
            validationResult = _packValidationData(
                false,
                uint48(cache.timestamp + tokenInfo.priceMaxAge),
                0
            );
        }
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        unchecked {
            (
                uint256 preCharge,
                uint256 maxFeePerGas,
                uint256 maxPriorityFeePerGas,
                address userOpSender,
                address tokenAddress
            ) = abi.decode(context, (uint256, uint256, uint256, address, address));

            IERC20Metadata token = IERC20Metadata(tokenAddress);
            TokenInfo memory tokenInfo = _tokenInfo[token];

            uint256 gasPrice = maxFeePerGas == maxPriorityFeePerGas ||
                maxFeePerGas < maxPriorityFeePerGas + block.basefee
                ? maxFeePerGas
                : maxPriorityFeePerGas;

            if (mode == PostOpMode.postOpReverted) {
                emit PostOpReverted(userOpSender, preCharge);
                return;
            }

            uint256 _cachedPrice = uint256(updatePrice(OracleQuery(NATIVE, token), oracle, false));
            uint256 cachedPriceWithMarkup = (_cachedPrice * PRICE_DENOMINATOR) /
                uint256(tokenInfo.priceMarkup);
            uint256 actualChargeNative = actualGasCost + uint256(REFUND_POSTOP_COST) * gasPrice;
            uint256 actualTokenNeeded = (actualChargeNative * PRICE_DENOMINATOR) /
                cachedPriceWithMarkup;

            if (preCharge > actualTokenNeeded) {
                token.safeTransfer(userOpSender, preCharge - actualTokenNeeded);
            } else if (preCharge < actualTokenNeeded) {
                // slither-disable-next-line arbitrary-send-erc20
                token.safeTransferFrom(userOpSender, address(this), actualTokenNeeded - preCharge);
            }

            emit UserOperationSponsored(
                userOpSender,
                actualTokenNeeded,
                actualGasCost,
                _cachedPrice
            );
        }
    }

    receive() external payable {}
}
