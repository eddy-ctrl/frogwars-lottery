const { ethers, network } = require("hardhat");
const { contractAddresses } = require("../../frontend/constants");

async function main() {
    let deployer   = await ethers.getSigner();
    let chainID             = await deployer.getChainId();

    const Announcer    = await ethers.getContractFactory("WinnerAnnouncer");
    const announcerAddress      = "0x854b1cb04296594427db0f7e96bccbc35a05638b";
    const announcer           = await Announcer.attach(announcerAddress);

    let tx = await announcer.requestRandomWinner({from: deployer.address, value: ethers.utils.parseEther("0.5")});
    console.log(`Lottery End (KeepUp Performed): ${tx.hash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })