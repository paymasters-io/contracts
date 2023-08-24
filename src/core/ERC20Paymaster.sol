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

/// @notice Based on eth-infinitism 'TokenPaymaster'
contract ERC20PaymastersIo is BasePaymaster, OracleHelper, IERC20PaymastersIo {
    using SafeERC20 for IERC20;

    uint256 constant PRICE_DENOMINATOR = 1e26;
    uint256 constant REFUND_POSTOP_COST = 41000;

    constructor(
        IEntryPoint _entryPoint,
        address _owner,
        TokenInfo memory _nativeTokenInfo
    ) BasePaymaster(_entryPoint) Ownable(_owner) {
        tokenInfo[IERC20Metadata(address(0x0))] = _nativeTokenInfo;
    }

    function setOracle(Oracle _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleChanged(_oracle);
    }

    function setTokenTicker(IERC20Metadata token, string calldata ticker) external onlyOwner {
        tokenInfo[token].ticker = ticker;
        emit TokenTickerAdded(address(token), ticker);
    }

    function addToken(IERC20Metadata token, TokenInfo memory _tokenInfo) external onlyOwner {
        if (_tokenInfo.priceMarkup > 2 * PRICE_DENOMINATOR || _tokenInfo.priceMarkup < PRICE_DENOMINATOR)
            revert PriceMarkupOutOfBounds(_tokenInfo.priceMarkup, PRICE_DENOMINATOR);
        _tokenInfo.decimals = token.decimals();
        tokenInfo[token] = _tokenInfo;

        emit TokenAdded(address(token), _tokenInfo.proxyOrFeed, _tokenInfo.priceMarkup, _tokenInfo.priceMaxAge);
    }

    function removeToken(IERC20Metadata token) external onlyOwner {
        delete tokenInfo[token];
        emit TokenRemoved(address(token));
    }

    function withdraw(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function _validateToken(IERC20Metadata token) internal view {
        if (
            address(token) == address(0x0) ||
            tokenInfo[token].proxyOrFeed == address(0x0) ||
            bytes(tokenInfo[token].ticker).length == 0
        ) {
            revert TokenNotSupported(address(token));
        }
    }

    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationResult) {
        // TODO
        // validationResult = _packValidationData(
        //         false,
        //         uint48(cache[...].timestamp + tokenInfo[...].priceMaxAge),
        //         0
        //     );
    }

    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        // TODO
    }

    receive() external payable {}
}
