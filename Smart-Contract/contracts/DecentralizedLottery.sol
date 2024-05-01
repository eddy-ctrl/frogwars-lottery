// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Imports
import "@chainlink/contracts/src/v0.8/automation/interfaces/KeeperCompatibleInterface.sol";
import "./DecentralizedLotteryInterface.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/ICallProxy.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Custom errors
error AdminBadRole();
error Lottery__NotEnoughBidEntered();
error Lottery__NotEnoughAllowanceEntered();
error Lottery__TransferToWinnerFailed();
error Lottery__BurnFailed();
error Lottery__NotOpen();
error Lottery__UpKeepNotNeeded(
    uint256 currentBalance,
    uint256 numOfPlayers,
    uint256 raffleState
);

// Contract
contract DecentralizedLottery is KeeperCompatibleInterface, DecentralizedLotteryInterface, AccessControl {
    // State Variables
    uint256 private entranceFee; // Fee to get one lottery ticket.
    IERC20 private entranceToken;
    uint256 private lastTimeStamp;
    uint256 private interval;

    address private recentWinner; // The most recent winner
    address[] private allPlayers;
    address public burner;

    LotteryState private _LotteryState;

    // Events
    event lotteryEnter(address indexed player);
    event winnerPicked(address indexed recentWinner);

    // Cross-chain
    uint256 public AnnouncerChainID;
    address public AnnouncerAddress;
    IDeBridgeGateExtended public deBridgeGate;

    bool public allowTestRandomness;

    //    Constructor
    constructor(address _entranceToken) {
        entranceToken = IERC20(_entranceToken);
        _LotteryState = LotteryState.CLOSED;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        allowTestRandomness = true;
        burner = msg.sender;
    }

    // Modifiers
    // The entered value is less then the entrance fee.
    modifier notEnoughBidEntered() {
        uint256 userBalance = entranceToken.balanceOf(msg.sender);
        if (userBalance < entranceFee) {
            revert Lottery__NotEnoughBidEntered();
        }

        uint256 allowance = entranceToken.allowance(msg.sender, address(this));
        if (allowance < entranceFee) {
            revert Lottery__NotEnoughAllowanceEntered();
        }

        _;
    }

    // Modifiers
    modifier onlyCrossChain {
        if (!allowTestRandomness) {
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
        }
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

    // Call this function only after testing the bridge and randomness.
    function disallowTestRandomness() external onlyAdmin {
        allowTestRandomness = false;
    }

    function setDeBridgeGate(IDeBridgeGateExtended deBridgeGate_) external onlyAdmin
    {
        deBridgeGate = deBridgeGate_;
    }

    function setEntranceFee(uint256 fee_) external onlyAdmin
    {
        entranceFee = fee_;
    }

    function setBurner() external onlyAdmin {
        burner = msg.sender;
    }

    function addChainSupport(
        uint256 _trustedChain,
        address _trustedAddress
    ) external onlyAdmin {
        AnnouncerChainID = _trustedChain;
        AnnouncerAddress = _trustedAddress;
    }

    // Enter the lottery ticket.
    function enterLottery() external notEnoughBidEntered override {
        if (_LotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        bool transferred = entranceToken.transferFrom(msg.sender, address(this), entranceFee);
        require(transferred, "failed to take fee");
        allPlayers.push(msg.sender);

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
        bool hasBalance = entranceToken.balanceOf(address(this)) > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    // Pick a random number;
    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyAdmin {
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
        address _recentWinner = allPlayers[index];
        recentWinner = _recentWinner;

        uint256 amount = entranceToken.balanceOf(address(this));
        uint256 winnerAmount = amount / 10 * 5;
        uint256 poolAmount = amount/ 10 * 3;
        uint256 burnAmount = amount - (winnerAmount + poolAmount);

        bool success = entranceToken.transfer(recentWinner, winnerAmount);
        if (!success) {
            revert Lottery__TransferToWinnerFailed();
        }
        success = entranceToken.transfer(burner, burnAmount);
        if (!success) {
            revert Lottery__BurnFailed();
        }

        emit winnerPicked(recentWinner);
        _LotteryState = LotteryState.CLOSED;
        allPlayers = new address[](0);
        lastTimeStamp = block.timestamp;
    }

    function startSession(uint256 _entranceFee, uint256 _interval) external onlyAdmin {
        require(_LotteryState == LotteryState.CLOSED, "can't start a session");

        entranceFee = _entranceFee;
        _LotteryState = LotteryState.OPEN;
        lastTimeStamp = block.timestamp;
        interval = _interval;
    }
}
