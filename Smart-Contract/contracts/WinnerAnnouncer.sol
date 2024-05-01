// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Imports
import "@openzeppelin/contracts/access/AccessControl.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGate.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/IDeBridgeGateExtended.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/interfaces/ICallProxy.sol";
import "@debridge-finance/debridge-protocol-evm-interfaces/contracts/libraries/Flags.sol";
import "./DecentralizedLotteryInterface.sol";

error AdminBadRole();

// Contract
contract WinnerAnnouncer is VRFConsumerBaseV2Plus, AccessControl {
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    IDeBridgeGateExtended public deBridgeGate;

    // Variables for chainlink random number function;
    bytes32 private immutable keyHash;
    uint256 public subscriptionId;
    uint32 public callbackGasLimit;
    uint32 private constant NO_OF_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // Variables for the cross-chain messaging
    uint256 public LotteryChainID;
    address public LotteryAddress;
    uint256 public ExecutionFee;
    uint256 public requestId;

    // Events
    event randomNumberPick(uint256 indexed requestId);
    event pickedRandomNumber(uint256 randomWord);

    // Testing
    bool public callOracle;

    // Modifiers

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    //    Constructor
    constructor(
        address vrfCoordinatorV2,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorV2);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;

        callOracle = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // View Functions

    // Get Num Words
    function getNumWords() public pure returns (uint256) {
        return NO_OF_WORDS;
    }

    // Get Request confirmations
    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    // Functions

    function _encodeReceiveCommand(uint256 _randomWord)  internal pure returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
            DecentralizedLotteryInterface.receiveRandomWord.selector,
            _randomWord
        );
    }


    function setDeBridgeGate(IDeBridgeGateExtended deBridgeGate_) external onlyAdmin
    {
        deBridgeGate = deBridgeGate_;
    }

    function setExecutionFee(uint256 fee_) external onlyAdmin
    {
        ExecutionFee = fee_;
    }

    function setSubscriptionId(uint256 subId_) external onlyAdmin {
        subscriptionId = subId_;
    }

    function setCallbackLimit(uint32 callbackLimit_) external onlyAdmin {
        callbackGasLimit = callbackLimit_;
    }

    function setCallOracle() external onlyAdmin {
        callOracle = true;
    }

    function addChainSupport(
        uint256 _trustedChain,
        address _trustedAddress
    ) external onlyAdmin {
        LotteryChainID = _trustedChain;
        LotteryAddress = _trustedAddress;
    }

    // Pick a random number;
    function requestRandomWinner() external payable onlyAdmin {
        requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: callbackGasLimit,
                numWords: NO_OF_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        // Emitting event
        emit randomNumberPick(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        if (callOracle) {
            bytes memory dstTxCall = _encodeReceiveCommand(randomWords[0]);

            // send the random word to the DecentralizedLottery
            _send(dstTxCall, ExecutionFee);
        } else {
            emit pickedRandomNumber(randomWords[0]);
        }
    }

    function announceWinner(uint256 randomWord_) external onlyAdmin {
        require(!callOracle, "only by chainlink oracle");

        bytes memory dstTxCall = _encodeReceiveCommand(randomWord_);

        // send the random word to the DecentralizedLottery
        _send(dstTxCall, ExecutionFee);
    }

    function _send(bytes memory _dstTransactionCall, uint256 _executionFee) internal {
        //
        // sanity checks
        //
        uint256 protocolFee = deBridgeGate.globalFixedNativeFee();
        require(
            address(this).balance >= (protocolFee + _executionFee),
            "fees not covered by the msg.value"
        );

        // we bridge as much asset as specified in the _executionFee arg
        // (i.e. bridging the minimum necessary amount to to cover the cost of execution)
        // However, deBridge cuts a small fee off the bridged asset, so
        // we must ensure that executionFee < amountToBridge
        uint assetFeeBps = deBridgeGate.globalTransferFeeBps();
        uint amountToBridge = _executionFee;
        uint amountAfterBridge = amountToBridge * (10000 - assetFeeBps) / 10000;

        //
        // start configuring a message
        //
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;

        // use the whole amountAfterBridge as the execution fee to be paid to the executor
        autoParams.executionFee = amountAfterBridge;

        // Exposing nativeSender must be requested explicitly
        // We request it bc of CrossChainCounter's onlyCrossChain modifier
        autoParams.flags = Flags.setFlag(
            autoParams.flags,
            Flags.PROXY_WITH_SENDER,
            true
        );

        // if something happens, we need to revert the transaction, otherwise the sender will loose assets
        autoParams.flags = Flags.setFlag(
            autoParams.flags,
            Flags.REVERT_IF_EXTERNAL_FAIL,
            true
        );

        autoParams.data = _dstTransactionCall;
        autoParams.fallbackAddress = abi.encodePacked(msg.sender);

        deBridgeGate.send{value: (protocolFee + _executionFee)}(
            address(0), // _tokenAddress
            amountToBridge, // _amount
            LotteryChainID, // _chainIdTo
            abi.encodePacked(LotteryAddress), // _receiver
            "", // _permit
            true, // _useAssetFee
            0, // _referralCode
            abi.encode(autoParams) // _autoParams
        );
    }

    receive() external payable {}

    function withdrawBalance() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }
}
