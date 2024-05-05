const { ethers, network } = require("hardhat");
const { contractAddresses } = require("../../frontend/constants");

async function main() {
    let deployer   = await ethers.getSigner();
    let chainID             = await deployer.getChainId();

    const Lottery    = await ethers.getContractFactory("DecentralizedLottery");
    const lotteryAddress             = contractAddresses[chainID][0];
    const lottery           = await Lottery.attach(lotteryAddress);
    const adminRole                 = "0x0000000000000000000000000000000000000000000000000000000000000000";

    let tx = await lottery.grantRole(adminRole, "0x319a59ac483A52A4ed3c82Ed1B8B6883BFA80139", {from: deployer.address});
    console.log(`Grant Role: ${tx.hash}`);

    tx = await lottery.revokeRole(adminRole, deployer.address, {from: deployer.address});
    console.log(`Revoke Role: ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })