// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@paymasters-io/modules/BaseModule.sol";

contract AllowListModule is BaseModule {
    mapping(address => bool) public allowedAddresses;

    event AddressAdded(address indexed _address);
    event AddressRemoved(address indexed _address);

    constructor(
        address _paymaster,
        address _moduleAttester,
        address _manager
    ) BaseModule(_paymaster, _moduleAttester, _manager) {}

    function addAddress(address _address) public onlyManager {
        require(_address != address(0), "Invalid address");
        require(!allowedAddresses[_address], "Address is already allowed");
        allowedAddresses[_address] = true;
        emit AddressAdded(_address);
    }

    function removeAddress(address _address) public onlyManager {
        require(allowedAddresses[_address], "Address is not allowed");
        allowedAddresses[_address] = false;
        emit AddressRemoved(_address);
    }

    function isAddressAllowed(address _address) public view returns (bool) {
        return allowedAddresses[_address];
    }

    function register() external payable override returns (address) {
        return super.register(true);
    }

    function _validate(
        bytes calldata /** verificationData */,
        address user
    ) internal view virtual override returns (bool) {
        return isAddressAllowed(user);
    }

    function _postValidate(
        bytes32 moduleData,
        uint256 actualGasCost,
        address sender
    ) internal virtual override {}

    receive() external payable virtual override {}
}
