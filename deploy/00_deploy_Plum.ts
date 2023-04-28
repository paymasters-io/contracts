import { Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { SigningKey } from "ethers/lib/utils";

require("dotenv").config();

export default async function deployPlum(hre: HardhatRuntimeEnvironment) {
  const PRIVATE_KEY = process.env.PRIVATE_KEY as ethers.BytesLike | SigningKey;
  const wallet = new Wallet(PRIVATE_KEY);
  const deployer = new Deployer(hre, wallet);
  const plumArtifact = await deployer.loadArtifact("PlumStore");

  const plumStore = await deployer.deploy(plumArtifact);

  console.log(`plumStore address: ${plumStore.address}`);
}
