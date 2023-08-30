// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IProxy - Helper interface to access the singleton address of the Proxy on-chain.
 * @author Richard Meissner - @rmeissner
 */
interface IProxy {
    function masterCopy() external view returns (address);

    function upgradeImplementation(address _newSingleton) external;
}

/**
 * @title SafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
 *
 * initial authors: Gnosis Team
 * @author Stefan George - <stefan@gnosis.io>
 * @author Richard Meissner - <richard@gnosis.io>
 *
 * changes:
 * paymasters.io team
 */
contract ProxyUpgradeable {
    // Singleton and owner always needs to be first declared variables, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;
    address internal immutable upg;

    /**
     * @notice Constructor function sets address of singleton contract.
     * @param _singleton Singleton address.
     */
    constructor(address _singleton, address _upg) {
        require(_singleton != address(0), "zero addr");
        require(_upg != address(0), "upg err");
        singleton = _singleton;
        upg = _upg;
    }

    function upgradeImplementation(address _newSingleton) external {
        require(msg.sender == upg, "upg err");
        singleton = _newSingleton;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    event Received(address indexed sender, uint256 value);
}
