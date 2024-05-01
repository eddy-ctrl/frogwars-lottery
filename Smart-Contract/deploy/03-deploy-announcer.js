const { network, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");
const {verify} = require('../utils/verify')

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("30");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  let vrfCoordinatorV2Address, subscriptionId;


  vrfCoordinatorV2_5Address = networkConfig[chainId]["vrfCoordinatorV2_5"];
  subscriptionId = networkConfig[chainId]["subscriptionId"];

  const entranceFee = networkConfig[chainId]["entranceFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];
  const interval = networkConfig[chainId]["interval"];

  const args = [vrfCoordinatorV2_5Address, gasLane, subscriptionId, callbackGasLimit];
  const DecentralizedLottery = await deploy("WinnerAnnouncer", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    log("verifying...");
    await verify(DecentralizedLottery.address, args)

    
}
log("---------------------------------------------------------")







};
module.exports.tags = ["all", "DecentralizedLottery"]