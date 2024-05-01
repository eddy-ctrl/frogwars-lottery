const { ethers } = require("hardhat");

const networkConfig = {
  4: {
    name: "rinkeby",
    vrfCoordinatorV2: "0x6168499c0cFfCaCD319c818142124B7A15E857ab",
    entranceFee: ethers.utils.parseEther("0.01"),
    gasLane: "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
    subscriptionId: "8114",
    callbackGasLimit: "500000",
    interval: '30'
},
  31337: {
    name: "hardhat",
    entranceFee: ethers.utils.parseEther("0.01"),
    gasLane: "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
    callbackGasLimit: "500000",
    interval: '30'

  },
  // Polygon Mainnet
  // https://docs.chain.link/vrf/v2/subscription/supported-networks#polygon-matic-mainnet
  137: {
    name: "polygon",
    vrfCoordinatorV2_5: "0xec0Ed46f36576541C75739E915ADbCb3DE24bD77",
    gasLane: "0x719ed7d7664abc3001c18aac8130a2265e1e70b7e036ae20f3ca8b92b3154d86",
    subscriptionId: "0x9510d8aff251c51d5eb9e439c88ec174dd30e86d4a4ee5eb6d73c6be38bd2f24",
    callbackGasLimit: "500000",
  },
  // Linea Mainnet
  59144: {
    name: "linea",
    entranceToken: "0x21d624c846725abe1e1e7d662e9fb274999009aa",
    entranceFee: ethers.utils.parseEther("0.01"),
    interval: '30'
  }
};

const developmentChains = ["hardhat", "localhost"];
module.exports = { networkConfig, developmentChains };
