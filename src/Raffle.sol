// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RaffleCustomErrors} from "./interfaces/CustomErrors.sol";
/**
 * @title A raffle contract.
 * @author Anton
 * @notice This contract showing the raffle contract.
 * @dev Raffle contract which implements Chainlink VRF and Automation.
 */
contract Raffle is RaffleCustomErrors {
    uint256 private immutable entranceFee;
    uint256 private immutable interval;
    uint256 private lastTimeStamp;
    address payable[] players;

    event RaffleEntered(address indexed player);

    constructor(uint256 _entranceFee, uint256 _interval) {
        entranceFee = _entranceFee;
        interval = _interval;
    }

    // people pay a fee to enter raffle
    function enterRaffle() external payable {
        if (msg.value < entranceFee) {
            revert Raffle_NotEnoughFee();
        }
        players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // 1. Generate rand number.
    // 2. Use that number to select a winner.
    // 3. Function should be called automatically when some time interval is passed.
    function selectWinner() external {

    }

    function getEntranceFee() public view returns (uint256) {
        return entranceFee;
    }
}
