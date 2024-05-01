// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Imports
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/libraries/Flags.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// Custom errors
// Contract
interface DecentralizedLotteryInterface {
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    // View Functions

    // get entrance fee.
    function getEntranceFee() external view returns (uint256);

    // Get player
    function getPlayer(uint256 index) external view returns (address);

    // Get Recent Winner
    function getRecentWinner() external view returns (address);

    // Get Lottery State
    function getLotteryState() external view returns (LotteryState);

    // Get Numbers of players
    function getNumbersOfPlayers() external view returns (uint256);

    // Get last block timestamp
    function getLastTimeStamp() external view returns (uint256);

    // Get Interval
    function getInterval() external view returns (uint256);

    // Functions

    // Enter the lottery ticket.
    function enterLottery() external payable;

    // TODO: make sure that the message is received from winner announcer
    function receiveRandomWord(
        uint256 randomWord
    ) external;
}
