// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRaffleCustomErrors} from "./interfaces/ICustomErrors.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A raffle contract.
 * @author Anton
 * @notice This contract is showing the raffle logic on chain.
 * @dev Raffle contract which implements Chainlink VRF and Automation.
 */
contract Raffle is VRFConsumerBaseV2Plus, IRaffleCustomErrors {
    enum RaffleStatus {
        Open,
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
    
    event RaffleEntered(address indexed player);
    event WinnerSelected(address indexed winner);

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

    /**
     * @dev To participate in raffle players should enter into the raffle.
     * 1. To enter into the raffle players should pay a 'entranceFee' fee.
     * 2. Players can enter inthe raffle only if it is in 'Open' status. 
     */
    function enterRaffle() external payable {
        if (raffleStatus != RaffleStatus(0)) {
            revert Raffle_RaffleIsInProgress();
        }
        if (msg.value < entranceFee) {
            revert Raffle_NotEnoughFee();
        }

        players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This function will be called by Chainlnk nodes, in order to see
     * if the lottery is ready to select a new winner. The following should be true
     * in order for 'upkeepNeeded' to be true:
     * 1. Time 'interval' has elapsed since the 'lastTimeStamp'.
     * 2. The lottery is in 'Open' status.
     * 3. The contract has ETH and has players.
     * 4. Implicitly, your subscription  has LINK tokens.
     * @param - ignored.
     * @return upkeepNeeded - returns true if it is a time to restart the lottery.
     * @return - ignored.
     */
    function checkUpkeep(bytes memory /* checkData */) 
        public 
        view 
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
       bool isTimeElapsed = (block.timestamp - lastTimeStamp) >= interval;
       bool isLotteryOpen = raffleStatus == RaffleStatus(0);
       bool hasETH = address(this).balance > 0;
       bool hasPlayers = players.length > 0;
       upkeepNeeded = isTimeElapsed && isLotteryOpen && hasETH && hasPlayers; // if all the statements true -> upkeepNeeded = true.
    }
    
    /**
     * @dev Automatically calculate a random winner with the help of Chinlink VRF,
     * if the 'upkeepNeeded' value returned from 'checkUpkeep' function is true, 
     * othervise revert.
     * @param - ignored.
     */
    function performUpKeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle_UpKeepNeededFalse(address(this).balance, players.length, uint256(raffleStatus));
        }
        
        raffleStatus = RaffleStatus(1);
        
        // Request random number from VRF
        s_vrfCoordinator.requestRandomWords(
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
    }

    /**
     * @dev Chainlink nodes will do a callback to this funcition once calculated a random number.
     * Once random number is returned, we calculate a 'randomWinnerIndex' and select 'theWinner'
     * from the 'players' array.
     * @param - ignored. 
     * @param randomWords - randomly calcuated 'uint256' number by VRF.
     */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override {
        uint256 randomWinnerIndex = randomWords[0] % players.length;
        address payable theWinner = players[randomWinnerIndex];
        recentWinner = theWinner;

        raffleStatus = RaffleStatus(0);
        players = new address payable[](0);
        lastTimeStamp = block.timestamp;
        
        (bool success, ) = theWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
        emit WinnerSelected(theWinner);
    }

    /**
     * @dev Function return a 'entranceFee' fee.
     * @return return 'entranceFee' value.
     */
    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }

    /**
     * @dev Function return a current status of the Raffle.
     * @return RaffleStatus return 'RaffleStatus' status in which currently the lottery is.
     */
    function getRaffleStatus() public view returns (RaffleStatus) {
        return raffleStatus;        
    }

    /**
     * @dev Getter function to return 'players' array.
     * @return array of players addresses.
     */
    function getPlayers() public view returns(address payable[] memory) {
        return players;
    } 
}
