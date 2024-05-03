const { ethers, network } = require("hardhat");
const { contractAddresses } = require("../../frontend/constants");

async function main() {
    let deployer   = await ethers.getSigner();
    let chainID             = await deployer.getChainId();

    const Lottery    = await ethers.getContractFactory("DecentralizedLottery");
    const lotteryAddress             = contractAddresses[chainID][0];
    const lottery           = await Lottery.attach(lotteryAddress);

    // Arguments
    const interval = 60 * 10;
    const fee = ethers.utils.parseEther("0.01");

    let tx = await lottery.startSession(fee, interval, {from: deployer.address});
    console.log(`Start Session: ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })