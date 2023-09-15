// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "./Config.sol";
import "../src/core/ModularPaymaster.sol";

contract DeployModularPaymaster is Script {
    NetworkConfig config;

    function setUp() public {
        Config conf = new Config();
        config = conf.getActiveNetworkConfig();
    }

    function run() public {
        vm.startBroadcast();
        ModularPaymaster mp = new ModularPaymaster(
            IEntryPoint(config.entrypoint),
            IModuleAttestations(config.moduleAtts),
            msg.sender
        );
        vm.stopBroadcast();
    }
}
