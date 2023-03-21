import "@matterlabs/hardhat-zksync-toolbox"
import fs from "fs"
import "hardhat-preprocessor"
import {HardhatUserConfig} from "hardhat/config"

require("dotenv").config()

function getRemappings() {
    return fs
        .readFileSync("remappings.txt", "utf8")
        .split("\n")
        .filter(Boolean) // remove empty lines
        .map((line) => line.trim().split("="))
}

const config: HardhatUserConfig = {
    zksolc: {
        version: "1.3.5",
        compilerSource: "binary", // binary or docker
        settings: {
            experimental: {
                dockerImage: "matterlabs/zksolc", // required for compilerSource: "docker"
                tag: "latest", // required for compilerSource: "docker"
            },
            isSystem: true,
        },
    },
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            zksync: true, // enables zksync in hardhat local network
        },
        goerli: {
            url: process.env.GOERLI_RPC_URL, // URL of the Ethereum Web3 RPC (optional)
        },
        zkTestnet: {
            url: "https://zksync2-testnet.zksync.dev", // URL of the zkSync network RPC
            ethNetwork: "goerli", // Can also be the RPC URL of the Ethereum network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
            zksync: true,
            verifyURL: "https://zksync2-testnet-explorer.zksync.dev/contract_verification",
        },
    },
    solidity: {
        version: "0.8.15",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: true,
        },
    },
    paths: {
        sources: "./src",
        cache: "./cache_hardhat",
    },
    preprocess: {
        eachLine: (hre: any) => ({
            transform: (line: string) => {
                if (line.match(/^\s*import /i)) {
                    for (const [from, to] of getRemappings()) {
                        if (line.includes(from)) {
                            line = line.replace(from, to)
                            break
                        }
                    }
                }
                return line
            },
        }),
    },
}

export default config
