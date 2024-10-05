// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../script/Interractions.s.sol";

contract DeployRaffle is Script {
    function run() public {
        deploy();
    }

    function deploy() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        
        if (config.subscriptionId == 0) {
            // create subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = 
                createSubscription.createSubscription(config.vrfCoordinator, config.account);
            // fund subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator,
                config.subscriptionId,
                config.linkToken,
                config.account
            );
        }

        // deploy Raffle contract
        vm.startBroadcast(config.account); // config.account - means the following tx will be broadcasted from this account
        Raffle raffle = new Raffle(
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit,
            config.entranceFee, 
            config.interval
        );
        vm.stopBroadcast();
        
        // add Raffle contract as a consumer to subcription
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addNewConsumer(
            address(raffle), 
            config.vrfCoordinator,
            config.subscriptionId,
            config.account
        );

        return (raffle, helperConfig);
    }
}