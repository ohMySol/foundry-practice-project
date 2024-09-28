// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RaffleCustomErrors} from "./interfaces/CustomErrors.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A raffle contract.
 * @author Anton
 * @notice This contract showing the raffle contract.
 * @dev Raffle contract which implements Chainlink VRF and Automation.
 */
contract Raffle is VRFConsumerBaseV2Plus, RaffleCustomErrors {
    enum RaffleStatus {
        Open,
        Paused,
        InProgress
    }
    // VRF var-s
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS =  1;
    bytes32 private immutable keyHash;
    uint256 private immutable subscriptionId;
    uint32 private immutable callbackGasLimit;    
    // Raffle var-s
    uint256 private immutable entranceFee;
    uint256 private immutable interval;
    uint256 private lastTimeStamp;
    address payable[] players;
    address payable recentWinner;
    RaffleStatus public raffleStatus;

    // user 'address' => 'requestId' => 'calculationStatus' status
    //mapping (address => mapping(uint256 => calculationStatus)) public requestStatus;
    
    event RaffleEntered(address indexed player);

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId, 
        uint32 _callbackGasLimit,
        uint256 _entranceFee, 
        uint256 _interval
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        entranceFee = _entranceFee;
        interval = _interval;
        lastTimeStamp = block.timestamp;

        raffleStatus = RaffleStatus(0);
    }

    // people pay a fee to enter raffle
    function enterRaffle() external payable {
        if (raffleStatus != RaffleStatus(0)) {
            revert Raffle_RaffleIsOnPause();
        }
        if (msg.value < entranceFee) {
            revert Raffle_NotEnoughFee();
        }

        players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // 1. Generate rand number.
    // 2. Use that number to select a winner.
    // 3. Function should be called automatically when some time interval is passed.
    function selectWinner() external returns(uint256 requestId) {
        // Check if enough time passed
        if ((block.timestamp - lastTimeStamp) < interval) {
            revert Raffle_TimeIntervalNotElapsed();
        }
        
        raffleStatus = RaffleStatus(2);
        
        // Request random number from VRF
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: callbackGasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        //requestStatus[msg.sender][requestId] = calculationStatus.InProgress;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 randomWinnerIndex = randomWords[0] % players.length;
        address payable theWinner = players[randomWinnerIndex];
        recentWinner = theWinner;

        raffleStatus = RaffleStatus(0);
        
        (bool success, ) = theWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    /*
    if (requestStatus[msg.sender][requestId] == 0) {
            revert Raffle_RandomNumberCalculationIsInProgress();
        }
    */
}
