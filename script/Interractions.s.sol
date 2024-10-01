// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return(subId, vrfCoordinator);
    }

    /// This function will programmatically create a subscription fro local testing.
    function createSubscription(address _vrfCoordinator) public returns (uint256, address) {
        // solhint-disable
        console.log("Creating subscription on chain id: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        // solhint-disable
        console.log("Your subscription id is: ", subId);
        return(subId, _vrfCoordinator);
    }
    
    function run() public {
        createSubscriptionUsingConfig();
    }
}