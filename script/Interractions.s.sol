// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";



contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        (uint256 subId, ) = createSubscription(vrfCoordinator);
        return(subId, vrfCoordinator);
    }

    /// This function will programmatically create a subscription.
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

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    /// This function will programmatically fund a subscription.
    function fundSubscription(address _vrfCoordinator, uint256 _subscriptionId,address _linkToken) public {
        console.log("Funding subscription: ", _subscriptionId);
        console.log("Using VRFCoordinator: ", _vrfCoordinator);
        console.log("On chain id: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
            vm.stopBroadcast();
        }
    }
    
    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addCounsumerUsingConfig(address _mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        addNewConsumer(_mostRecentlyDeployed, vrfCoordinator, subscriptionId);        
    }

    /// This function will programmatically add a consumer to subscription.
    function addNewConsumer(address _consumerContract, address _vrfCoordinator, uint256 _subId) public { // '_consumerContract' is the most recently deployed Raffle contract
        console.log("Adding consumer for contract: ", _consumerContract);
        console.log("To vrfCoordinator: ", _vrfCoordinator);
        console.log("On chain id: ", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(_subId, _consumerContract);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedRaffleContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addCounsumerUsingConfig(mostRecentlyDeployedRaffleContract);
    }
}