import React, { useEffect, useState } from "react";
import { useWeb3Contract, useMoralis } from "react-moralis";
import { contractAddresses, abi, IERC20 } from "../constants";
import { ethers } from "ethers";
import { Loading, useNotification } from "web3uikit";
import Moralis from "moralis";

export default function EnterLottery() {
  const [entranceFee, setEntranceFee] = useState();
  const [lotteryNotOpen, setLotteryNotOpen] = useState(false);
  const [recentWinner, setRecentWinner] = useState();
  const [allPlayers, setAllPlayers] = useState();
  const [loading, setLoading] = useState(false);
  const [btnLoading, setBtnLoading] = useState(false);
  const [showFullAddress, setShowFullAddress] = useState(true);
  const [totalBalance, setTotalBalance] = useState("0.0");

  const { chainId: chainIdHex, isWeb3Enabled, account } = useMoralis();
  const dispatch = useNotification();

  const chainId = parseInt(chainIdHex);
  const lotteryAddress =
    chainId in contractAddresses ? contractAddresses[chainId][0] : null;
  const tokenAddress = chainId in contractAddresses ? contractAddresses[chainId][1] : null;

  const approveRaw = async function() {
    const web3Provider = await Moralis.enableWeb3(); // Get ethers.js web3Provider
    const gasPrice = await web3Provider.getGasPrice();

    const signer = web3Provider.getSigner();

    const contract = new ethers.Contract(tokenAddress, IERC20, signer);

    const transaction = await contract.approve(
        lotteryAddress,
        ethers.utils.parseEther("1000"),{
          gasLimit: 200000,
          gasPrice: gasPrice,
    });
    return transaction;
  }

  const enterLotteryRaw = async function() {
    const web3Provider = await Moralis.enableWeb3(); // Get ethers.js web3Provider
    const gasPrice = await web3Provider.getGasPrice();

    const signer = web3Provider.getSigner();

    const contract = new ethers.Contract(lotteryAddress, abi, signer);

    const transaction = await contract.enterLottery({
      gasLimit: 2000,
      gasPrice: gasPrice,
    });
    return transaction;
  }

  const {
    runContractFunction: getEntranceFee,
    isLoading,
    isFetching,
  } = useWeb3Contract({
    abi,
    contractAddress: lotteryAddress,
    functionName: "getEntranceFee",
    params: {},
  });

  const { runContractFunction: getNumbersOfPlayers } = useWeb3Contract({
    abi,
    contractAddress: lotteryAddress,
    functionName: "getNumbersOfPlayers",
    params: {},
  });

  const { runContractFunction: getRecentWinner } = useWeb3Contract({
    abi,
    contractAddress: lotteryAddress,
    functionName: "getRecentWinner",
    params: {},
  });

  const { runContractFunction: getLotteryState } = useWeb3Contract({
    abi,
    contractAddress: lotteryAddress,
    functionName: "getLotteryState",
    params: {},
  });

  const { runContractFunction: getAllowance } = useWeb3Contract({
    abi: IERC20,
    contractAddress: tokenAddress,
    functionName: "allowance",
    params: {owner: account, spender: lotteryAddress},
  });

  const { runContractFunction: getTotalBalance } = useWeb3Contract({
    abi: IERC20,
    contractAddress: tokenAddress,
    functionName: "balanceOf",
    params: {account: lotteryAddress},
  });

  const handleClick = async () => {
    setBtnLoading(true);

    const allowanceWei = (await getAllowance());
    const allowance = parseFloat(ethers.utils.formatEther(allowanceWei));
    const fee = parseFloat(ethers.utils.formatUnits(entranceFee));

    if (allowance < fee) {
      let approveTx = undefined;
      try {
        approveTx = await approveRaw();
        await approveTx.wait(1);
        handleNewNotification(approveTx);
      } catch(error) {
        console.error(error);
        return;
      }
    }

    let tx = undefined;
    try {
      tx = await enterLotteryRaw();
      await handleSuccess(tx);
    } catch (error) {
      console.log(error);
    }

  };

  // Notifications
  const handleSuccess = async (tx) => {
    await tx.wait(1);
    handleNewNotification(tx);
    setBtnLoading(false);

    const getNumOfPlayers = (await getNumbersOfPlayers()).toString();
    setAllPlayers(getNumOfPlayers);

    const getBalance = await getTotalBalance();
    setTotalBalance(ethers.utils.formatEther(getBalance));
  };

  const handleNewNotification = () => {
    dispatch({
      type: "info",
      message: "Transaction Completed Successfully",
      title: "Transaction Notification",
      position: "topR",
      icon: "bell",
    });
  };

  useEffect(() => {
    if (isWeb3Enabled && lotteryAddress) {
      const getAll = async () => {
        const getFee = (await getEntranceFee()).toString();
        const getNumOfPlayers = (await getNumbersOfPlayers()).toString();
        const getWinner = await getRecentWinner();
        const getState = await getLotteryState();
        setEntranceFee(getFee);
        setAllPlayers(getNumOfPlayers);
        setRecentWinner(getWinner);
        console.log(`State is: ${getState}. Closed? ${(getState != 1)}`);
        setLotteryNotOpen(getState != 1);

        const getBalance = await getTotalBalance();
        setTotalBalance(ethers.utils.formatEther(getBalance));
      };
      getAll();
    }
  }, [isWeb3Enabled]);

  return (
    <div className="px-10 py-5">
      {lotteryAddress ? (
        <div className="space-y-5">
          <p className=" text-[50px] text-green-500 font-bold text-center space-x-5">
            Entrance Fee =
            <span className="text-green-500 px-5">
              {entranceFee && ethers.utils.formatUnits(entranceFee, "ether")} CRYSTAL
            </span>
          </p>
          <p className=" text-[50px] text-blue-400 font-bold text-center space-x-5">
            Current Pot =
            <span className="text-blue-400 px-5">
              {parseFloat(totalBalance).toFixed(4).toString()} CRYSTAL
            </span>
          </p>
          <p className="text-4xl text-gray-300 font-semibold text-center">Players = <span className="text-blue-500">
          {allPlayers && allPlayers}
            </span> </p>
          <p className="flex items-center gap-x-2 justify-center"> <img className="w-20" src="/images/award-img.png" alt="Winner" /> <span className="text-3xl text-gray-300"> Recent Winner: {recentWinner && !showFullAddress ? recentWinner : recentWinner?.slice(0,6) + "..." + recentWinner?.slice(recentWinner?.length-6)} </span>
           <span>
            <button className="bg-blue-500 text-white px-3 py-1 rounded-md" onClick={() => setShowFullAddress(!showFullAddress)}>{showFullAddress ? "View" : "Hide"}</button>
           </span>
          </p>
          <div className="text-center">
            <button
              className="cursor-pointer mt-12 w-40 h-10 px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700"
              disabled={isFetching || isLoading || loading || btnLoading || lotteryNotOpen}
              onClick={handleClick}
            >
              {btnLoading || isLoading || isFetching ? (
                <div>
                  <Loading fontSize={20} direction="right" spinnerType="wave" />
                </div>
              ) : (
                <div>{lotteryNotOpen ? "Lottery Not Open" : "Enter Lottery"}</div>
              )}
            </button>
          </div>
        </div>
      ) : (
        <div className="text-white text-center">Wallet Not Connected To Linea Mainnet (Connect Using Connect wallet Button in the top right, then switch to Linea Mainnet)</div>
      )}
    </div>
  );
}
