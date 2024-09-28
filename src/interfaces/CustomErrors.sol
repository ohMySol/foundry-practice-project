// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface RaffleCustomErrors {
    /// Indicates that user provide not enough fee value to enter a raffle.
    error Raffle_NotEnoughFee();

    /// Indicates that we can't select a new winner, because time interval not yet passed.
    error Raffle_TimeIntervalNotElapsed();

    /// Indicates that tthere is an error with the prize transfer for the winner.
    error Raffle_TransferFailed();

    // Indicates that currently raffle contract is paused.
    error Raffle_RaffleIsOnPause();
}