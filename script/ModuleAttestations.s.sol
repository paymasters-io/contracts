// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "./Config.sol";
import "../src/modules/ModuleAttestations.sol";

contract DeployModuleAttestations is Script {
    NetworkConfig config;

    function setUp() public {
        Config conf = new Config();
        config = conf.getActiveNetworkConfig();
    }

    function run() public {
        vm.startBroadcast();
        ModuleAttestations mp = new ModuleAttestations(
            IEAS(config.eas),
            config.schemaId,
            msg.sender
        );
        vm.stopBroadcast();
    }
}
