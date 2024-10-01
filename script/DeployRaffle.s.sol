// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {
    }

    function deploy() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        
        if (config.subscriptionId == 0) {
            // create subscription
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit,
            config.entranceFee, 
            config.interval
        );
        vm.stopBroadcast();
        
        return (raffle, helperConfig);
    }
}