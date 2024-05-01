// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Imports
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./DecentralizedLotteryInterface.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/ICallProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Custom errors
error AdminBadRole();
error Lottery__NotEnoughEthEntered();
error Lottery__TransferToWinnerFailed();
error Lottery__NotOpen();
error Lottery__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 numOfPlayers,
    uint256 raffleState
);

// Contract
contract DecentralizedLottery is KeeperCompatibleInterface, DecentralizedLotteryInterface, AccessControl {
    // State Variables
    uint256 private immutable entranceFee; // Fee to get one lottery ticket.
    uint256 private lastTimeStamp;
    uint256 private immutable interval;

    address private recentWinner; // The most recent winner
    address payable[] private allPlayers;

    LotteryState private _LotteryState;

    // Events
    event lotteryEnter(address indexed player);
    event randomNumberPick(uint256 indexed requestId);
    event winnerPicked(address indexed recentWinner);

    // Cross-chain
    uint256 public AnnouncerChainID;
    address public AnnouncerAddress;
    IDeBridgeGateExtended public deBridgeGate;

    //    Constructor
    constructor(
        uint256 _entranceFee,
        uint256 _interval
    ) {
        entranceFee = _entranceFee;
        _LotteryState = LotteryState.OPEN;
        lastTimeStamp = block.timestamp;
        interval = _interval;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Modifiers
    // The entered value is less then the entrance fee.
    modifier notEnoughEthEntered() {
        if (msg.value < entranceFee) {
            revert Lottery__NotEnoughEthEntered();
        }
        _;
    }

    // Modifiers
    modifier onlyCrossChain {
        // take the callProxy instance
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());

        // caller must be CallProxy
        require(address(callProxy) == msg.sender);

        // origin chain must be known
        require(callProxy.submissionChainIdFrom() == AnnouncerChainID);

        // native sender (initiator of the txn on the origin chain) must be trusted
        // Bytes can't be compared directly, so take the hashes of them
        require(
            keccak256(callProxy.submissionNativeSender())
            == keccak256(abi.encodePacked(AnnouncerAddress))
        );

        // execute the rest
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    // View Functions

    // get entrance fee.
    function getEntranceFee() public override view returns (uint256) {
        return entranceFee;
    }

    // Get player
    function getPlayer(uint256 index) public override view returns (address) {
        return allPlayers[index];
    }

    // Get Recent Winner
    function getRecentWinner() public override view returns (address) {
        return recentWinner;
    }

    // Get Lottery State
    function getLotteryState() public override view returns (LotteryState) {
        return _LotteryState;
    }

    // Get Numbers of players
    function getNumbersOfPlayers() public override view returns (uint256) {
        return allPlayers.length;
    }

    // Get last block timestamp
    function getLastTimeStamp() public override view returns (uint256) {
        return lastTimeStamp;
    }

    // Get Interval
    function getInterval() public override view returns (uint256) {
        return interval;
    }

    // Functions

    function setDeBridgeGate(IDeBridgeGateExtended deBridgeGate_) external onlyAdmin
    {
        deBridgeGate = deBridgeGate_;
    }

    function addChainSupport(
        uint256 _trustedChain,
        address _trustedAddress
    ) external onlyAdmin {
        AnnouncerChainID = _trustedChain;
        AnnouncerAddress = _trustedAddress;
    }

    // Enter the lottery ticket.
    function enterLottery() external payable notEnoughEthEntered override {
        if (_LotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        allPlayers.push(payable(msg.sender));

        //   Emitting events
        emit lotteryEnter(msg.sender);
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = (_LotteryState == LotteryState.OPEN);
        bool timePassed = ((block.timestamp - lastTimeStamp) > interval);
        bool hasPlayers = (allPlayers.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // Pick a random number;
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                allPlayers.length,
                uint256(_LotteryState)
            );
        }

        _LotteryState = LotteryState.CALCULATING;
        // Now you may call the winner announcer
    }

    function receiveRandomWord(
        uint256 randomWord
    ) external override onlyCrossChain {
        require(_LotteryState == LotteryState.CALCULATING, "required performUpkeep()");

        uint256 index = randomWord % allPlayers.length;
        address payable _recentWinner = allPlayers[index];
        recentWinner = _recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferToWinnerFailed();
        }
        emit winnerPicked(recentWinner);
        _LotteryState = LotteryState.OPEN;
        allPlayers = new address payable[](0);
        lastTimeStamp = block.timestamp;
    }
}
