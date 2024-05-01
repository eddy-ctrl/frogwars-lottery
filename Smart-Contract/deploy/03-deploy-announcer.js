const { network, ethers } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../helper-hardhat-config");
const {verify} = require('../utils/verify')

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;

  console.log(`ChainID: ${chainId}`);

  const vrfCoordinatorV2_5Address = networkConfig[chainId]["vrfCoordinatorV2_5"];
  const subscriptionId = networkConfig[chainId]["subscriptionId"];

  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];

  const args = [vrfCoordinatorV2_5Address, gasLane, subscriptionId, callbackGasLimit];
  const WinnerAnnouncer = await deploy("WinnerAnnouncer", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
    nonce: 7
  });

  if (!developmentChains.includes(network.name) && process.env.POLYGONSCAN_API_KEY) {
    log("verifying...");
    await verify(WinnerAnnouncer.address, args)
  }
  log("---------------------------------------------------------")
};
module.exports.tags = ["all", "WinnerAnnouncer"]