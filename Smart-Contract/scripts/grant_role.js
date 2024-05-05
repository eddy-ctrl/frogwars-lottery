const { ethers, network } = require("hardhat");
const { contractAddresses } = require("../../frontend/constants");

async function main() {
    let deployer   = await ethers.getSigner();
    let chainID             = await deployer.getChainId();

    const Lottery    = await ethers.getContractFactory("DecentralizedLottery");
    const lotteryAddress             = contractAddresses[chainID][0];
    const lottery           = await Lottery.attach(lotteryAddress);

    let tx = await lottery.performUpkeep(0x00, {from: deployer.address});
    console.log(`Lottery End (KeepUp Performed): ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })