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

  const entranceToken = networkConfig[chainId]["entranceToken"];

  const args = [entranceToken];
  const DecentralizedLottery = await deploy("DecentralizedLottery", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (!developmentChains.includes(network.name) && process.env.LINEASCAN_API_KEY) {
    log("verifying...");
    await verify(DecentralizedLottery.address, args)
  }
  log("---------------------------------------------------------")
};
module.exports.tags = ["all", "Lottery"]