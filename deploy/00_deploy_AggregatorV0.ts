import { Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { SigningKey } from "ethers/lib/utils";

require("dotenv").config();

export default async function deployAggregatorV0(hre: HardhatRuntimeEnvironment) {
  const PRIVATE_KEY = process.env.PRIVATE_KEY as ethers.BytesLike | SigningKey;
  const wallet = new Wallet(PRIVATE_KEY);
  const deployer = new Deployer(hre, wallet);
  const AggregatorV0Artifact = await deployer.loadArtifact("AggregatorV0");

  const factory = await deployer.deploy(AggregatorV0Artifact);

  console.log(`AggregatorV0 address: ${factory.address}`);
}
