// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct NetworkConfig {
    // main
    address entrypoint;
    // atts module
    address moduleAtts;
    bytes32 schemaId;
    address eas;
    // token
    address initialToken;
    uint192 ttl;
    uint32 updateThreshold;
    uint64 priceMaxAge;
    uint32 priceMarkup;
    address feedNative;
    address feedToken;
}

contract Config {
    NetworkConfig activeNetworkConfig;

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[84531] = getBaseGoerliConfig();
        chainIdToNetworkConfig[31337] = getAnvilEthConfig();
        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getActiveNetworkConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getBaseGoerliConfig() internal pure returns (NetworkConfig memory baseNetworkConfig) {
        baseNetworkConfig = NetworkConfig({
            entrypoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            moduleAtts: address(0),
            schemaId: bytes32(0),
            eas: 0xAcfE09Fd03f7812F022FBf636700AdEA18Fd2A7A,
            initialToken: 0x1B85deDe8178E18CdE599B4C9d913534553C3dBf,
            ttl: 30 minutes,
            updateThreshold: 1e6,
            priceMaxAge: 5 hours,
            priceMarkup: 1e6,
            feedNative: 0xcD2A119bD1F7DF95d706DE6F2057fDD45A0503E2,
            feedToken: 0xb85765935B4d9Ab6f841c9a00690Da5F34368bc0
        });
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            entrypoint: address(0),
            moduleAtts: address(1),
            schemaId: bytes32(0),
            eas: address(0),
            initialToken: address(2),
            ttl: 30 minutes,
            updateThreshold: 1e6,
            priceMaxAge: 5 hours,
            priceMarkup: 1e6,
            feedNative: address(3),
            feedToken: address(4)
        });
    }
}
