// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "./Config.sol";
import "../src/core/ERC20Paymaster.sol";

contract DeployERC20Paymaster is Script {
    NetworkConfig config;

    function setUp() public {
        Config conf = new Config();
        config = conf.getActiveNetworkConfig();
    }

    function run() public {
        vm.startBroadcast();
        ERC20Paymaster mp = new ERC20Paymaster(
            IEntryPoint(config.entrypoint),
            TokenInfo({
                priceMaxAge: config.priceMaxAge,
                priceMarkup: config.priceMarkup,
                decimals: uint8(18),
                feed: config.feedNative
            }),
            config.ttl,
            config.updateThreshold,
            msg.sender
        );

        mp.addToken(
            IERC20Metadata(config.initialToken),
            TokenInfo({
                priceMaxAge: config.priceMaxAge,
                priceMarkup: config.priceMarkup,
                decimals: 0,
                feed: config.feedToken
            })
        );
        vm.stopBroadcast();
    }
}
