import {utils, Wallet} from "zksync-web3"
import * as ethers from "ethers"
import {HardhatRuntimeEnvironment} from "hardhat/types"
import {Deployer} from "@matterlabs/hardhat-zksync-deploy"
require("dotenv").config()

export default async function deployGreggsFactory(hre: HardhatRuntimeEnvironment) {
    const PRIVATE_KEY: string = process.env.PRIVATE_KEY || ""
    const wallet = new Wallet(PRIVATE_KEY)
    const deployer = new Deployer(hre, wallet)

    // getting the artifacts
    const factoryArtifact = await deployer.loadArtifact("GreggsFactory")
    const artifactA = await deployer.loadArtifact("src/pre-flight/General.sol:Paymaster")
    const artifactB = await deployer.loadArtifact("src/pre-flight/ApprovalBased.sol:Paymaster")

    // Getting the bytecode Hashes of the paymasters
    const bytecodeHashA = utils.hashBytecode(artifactA.bytecode)
    const bytecodeHashB = utils.hashBytecode(artifactB.bytecode)

    const factory = await deployer.deploy(
        factoryArtifact,
        [bytecodeHashA, bytecodeHashB, "0xe96C86eAA802CDD65a32433126c57B201Ab22d4a"],
        undefined,
        [artifactA.bytecode, artifactB.bytecode]
    )

    console.log(`GreggsFactory address: ${factory.address}`)

    await hre.run("verify:verify", {
        address: factory.address,
        contract: "src/pre-flight/factory/GreggsFactory.sol:GreggsFactory",
        constructorArguments: [
            bytecodeHashA,
            bytecodeHashB,
            "0xe96C86eAA802CDD65a32433126c57B201Ab22d4a",
        ],
    })
}

module.exports.tags = ["PF"]
