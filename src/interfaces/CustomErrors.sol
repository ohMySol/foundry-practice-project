// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface RaffleCustomErrors {
    /// Indicates that user provide not enough fee value to enter a raffle.
    error Raffle_NotEnoughFee();
}