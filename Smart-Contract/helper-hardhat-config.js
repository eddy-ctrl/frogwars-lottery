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
    vrfCoordinatorV2: "0xAE975071Be8F8eE67addBC1A82488F1C24858067",
    gasLane: "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd",
    subscriptionId: "67424379512663932332268623715423188826394628625772023051424377045293146648356",
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
