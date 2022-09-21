const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    log("----------------------------------------------------")
    log("Deploying Multisig and waiting for confirmations...")
    const multiSig = await deploy("MultiSignatureWallet", {
        from: deployer,
        args: [["0x47F9d0FCe873C6CFf06307474e92683f3b52af75","0x249c58922D22a7E2D0cb48089e56BE5eBAC0093A"],2],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`MultiSignatureWallet deployed at ${multiSig.address}`)
}

module.exports.tags = ["all", "multiSig"]
