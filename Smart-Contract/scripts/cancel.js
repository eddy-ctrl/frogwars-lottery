const { ethers, network } = require("hardhat")

async function cancelTx() {
    const nonce = 6;

    const [owner,  feeCollector, operator] = await ethers.getSigners();

    let tx = await owner.sendTransaction({
        to: owner.address,
        value: 0,
        nonce: nonce,
        gasPrice: 90000000000
    });
    console.log('Cancelled: ' + tx.hash);
}

cancelTx()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })