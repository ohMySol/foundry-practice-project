// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IRaffleCustomErrors} from "../../src/interfaces/ICustomErrors.sol";

contract RaffleTest is Test {
    Raffle public raffle; // blueprint of the Raffle contract.
    HelperConfig public helperConfig; // blueprint of the HelperConfig contract.
    HelperConfig.NetworkConfig networkConfig; //NEtworkConfig struct
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerSelected(address indexed winner);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle(); // create an instance of the deploy script.
        (raffle, helperConfig) = deployer.deploy(); // deploy Raffle contract.
        networkConfig = helperConfig.getConfigByChainId(block.chainid);
        vm.deal(alice, STARTING_PLAYER_BALANCE);
    }
    
    /*//////////////////////////////////////////////////
                initialization check test
    /////////////////////////////////////////////////*/
    function testRaffleContractInitializedWithOpenStatus() public view {
        assert(raffle.getRaffleStatus() == Raffle.RaffleStatus.Open);
    }

    /*//////////////////////////////////////////////////
                enterRaffle() tests
    /////////////////////////////////////////////////*/
    function testPlayerEntersTheRaffleWhenItIsInOpenStatus() public {
        vm.startPrank(alice);

        raffle.enterRaffle{value: raffle.getEntranceFee()}();
      
        address payable[] memory players = raffle.getPlayers();
        assert(players[0] == alice);
    }

    function testRaffleEmitEventWhenPlayerEnters() public {
        vm.startPrank(alice);
        vm.expectEmit(true, false, false, false, address(raffle)); // address(raffle) - expected entity which will emit an event

        emit RaffleEntered(alice); // expected event to be emitted

        raffle.enterRaffle{value: raffle.getEntranceFee()}();
    }

    function testRaffleRevertWhenPlayerPayNotEnoughFee() public {
        vm.startPrank(alice);

        vm.expectRevert(IRaffleCustomErrors.Raffle_NotEnoughFee.selector);
        raffle.enterRaffle();
    }

    // Test fails with the reason: "next call did not revert as expected"
    // Need to solve this.
    // If comment the expect.. line - test will show the expected revert error.
    function testRaffleRevertWhenPlayerEnterRaffleInNonOpenStatus() public {
        vm.prank(alice);
        
        raffle.enterRaffle{value: raffle.getEntranceFee()}();
        vm.warp(block.timestamp + networkConfig.interval + 1); // current block + 31 seconds.
        vm.roll(block.number + 1); // since the time has elapsed the new block has been added.
        raffle.performUpKeep(""); // change status to 'InProgress'
        
        vm.expectRevert(IRaffleCustomErrors.Raffle_RaffleIsInProgress.selector);
        vm.prank(alice);
        raffle.enterRaffle{value: raffle.getEntranceFee()}();
    }
}
