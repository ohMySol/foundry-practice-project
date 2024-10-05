// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {IHelperConfigCustomErrors} from "../src/interfaces/ICustomErrors.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    // VRF mock constructor arguments
    uint96 public constant MOCK_BASE_FEE = 0.025 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;
}

contract HelperConfig is Script, CodeConstants, IHelperConfigCustomErrors {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        uint256 entranceFee; 
        uint256 interval;
        address linkToken;
        address account;
    }
    NetworkConfig public localNetworkConfig;

    mapping (uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getLocalNetworkConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 _chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[_chainId].vrfCoordinator != address(0)) {
            return networkConfigs[_chainId];
        } else if (_chainId == LOCAL_CHAIN_ID) {
            return getLocalNetworkConfig();
        } else {
            revert HelperConfig_NotSupportedChain();
        }
    }

    function getLocalNetworkConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        } else {
            // deploy mocks.
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UNIT_LINK
            );
            LinkToken linkToken = new LinkToken();
            vm.stopBroadcast();

            // create config for local env network.
            localNetworkConfig = NetworkConfig({
                vrfCoordinator: address(vrfCoordinatorMock),
                keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                entranceFee: 0.01 ether,
                interval: 30, // 30 sec
                linkToken: address(linkToken),
                account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 //default sender from Base.sol
            });
            
            return localNetworkConfig;
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            entranceFee: 0.01 ether,
            interval: 30, // 30 sec
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xD34B89262A8B9da21745c085F61502AFD6144066
        });
    }
}