<p align="center">
    <img src="./img/logo_normal.jpg" height="200">
</p>
<div align="center">
  <h1 align="center">
  EIP4337 Paymaster Contracts
  </h1>
</div>

<div align="center">

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/paymasters-io/contracts/test.yml)
![GitHub](https://img.shields.io/github/license/paymasters-io/contracts?logo=github)
![GitHub contributors](https://img.shields.io/github/contributors/paymasters-io/contracts?logo=github)
![GitHub top language](https://img.shields.io/github/languages/top/paymasters-io/contracts)
![GitHub Repo stars](https://img.shields.io/github/stars/paymasters-io/contracts?style=social)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/paymasters-io/contracts?logo=github)](https://github.com/paymasters-io/contracts/commits/master)
[![Twitter Follow](https://img.shields.io/twitter/follow/paymasters_io?style=social)](https://twitter.com/paymasters_io)

**[paymasters.io](https://paymasters.io)** leverages account abstraction to provide the infrastructure from which users can access and use Paymasters, simplifying transactions and providing superior UX to apps. Opening the gateway to paymasters' discovery and use cases for web3.

[Build](#getting-started) •
[Test](#testing) •
[Report a bug](https://github.com/paymasters-io/contracts/issues/new?assignees=&labels=bug&template=01_BUG_REPORT.md&title=bug%3A+)
• [Questions](https://t.me/paymasters_io)

</div>

**[paymasters.io](https://paymasters.io)** core contract implementation supports the following:

### Off-Chain Identifier

Each paymaster has a corresponding off-chain identifier (**metadata**) that is uploaded to IPFS.
It is just to simplify the aggregation of usable gas sponsors for visual purposes (**app-ui/dashboard**).

### Access Control

**[paymasters.io](https://paymasters.io)** core contract uses a **schema-based** approach.

It introduced a schema-based approach for enabling access control features in a paymaster. By default, each paymaster core contract has three access control rules corresponding to the following:

- ERC20 gating
- nonce limiting
- NFT gating

### Validators

A validator is a **smart account** with the power to sign a valid `paymasterAndData` for our verifying paymaster.
A validator must be trusted to only sign valid transactions and is incentivized to do so.

### Signature Verification

**[paymasters.io](https://paymasters.io)** uses 3 signature verification paths

`0-of-3 (ERC20 Paymaster)`: When no signature is required, the paymaster functions as an ERC20 paymaster.

`1-of-3 (Verifying paymaster)`: Signature corresponding to the VALIDATOR must be present in the paymasterData.

`2-of-3 (Verifying paymaster with 2FA)`: Signatures corresponding to the VALIDATOR must be present in the paymasterData, additional entropy from an external signer is required.

  > **VALIDATOR (va)**:  A verified userOp hash signer for our verifying paymasters.
  >
  > **VALIDATION ADDRESS (vaa)**: A privileged address for a paymaster (i.e admin);

# Getting Started

## Requirements

Please install the following:

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)  
- [pnpm](https://pnpm.io/installation)
- [Foundry / Foundryup](https://github.com/gakonst/foundry)
  - This will install `forge`, `cast`, and `anvil`
  - You can run `forge --version` to verify your installation
  - To update, just run `Foundryup`
- [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
- [make](https://askubuntu.com/questions/161104/how-do-i-install-make)

## Quick Start

1. first, clone the repo

```sh
git clone https://github.com/paymasters-io/contracts
```

2. cd into the contracts folder

```sh
cd contracts
```

3. install dependencies

```sh
make install 
```

## Testing

```sh
make test
or 
pnpm test
```

## Deploying to a Network

Deploy [scripts](https://book.getfoundry.sh/tutorials/solidity-scripting.html) have been written for you, unless you want to modify and deploy differently.

### Setup

- rename `packages/*/.env.example` to `.env` and provide the required configurations
- `PRIVATE_KEY`: keep this out of GitHub
- `ETHERSCAN_API_KEY`: you can obtain this from [etherscan](https://etherscan.io)
- `<CHAIN>_RPC_URL`: most of the chains are pre-filled with a free RPC provider URL if you are using a private node provider. please update it.
- also, you need to hold some Testnet tokens in the chain you are deploying to.

### Deploying

```sh
make deploy chain=<chain symbol> contract=<contract name>
or 
pnpm deploy chain=<chain symbol> contract=<contract name>
```

if your chain does not support [EIP1559](#) transactions, you can use the legacy deployment script

```sh
make deploy-legacy chain=<chain symbol> contract=<contract name>
or
pnpm deploy-legacy chain=<chain symbol> contract=<contract name>
```

example: `make deploy chain=BSC contract=Paymaster`

This will run the following inside the specified target

```sh
forge script script/${contract}.s.sol:Deploy${contract} --rpc-url $${$(CHAIN)_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vv

or

forge script script/${contract}.s.sol:Deploy${contract} --rpc-url $${$(CHAIN)_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --legacy  -vv
```

### Locally

- To start a local network run:

```sh
make local
```

This boots up a local blockchain for you with a test private key;

- To deploy to the local network:

```sh
make deploy-local contract=<contract name>
```

example: `make deploy-local target=evm contract=PaymasterCore`

### Forks

You can also deploy on a forked network

- To start a forked network run:

```sh
make fork chain=<chain symbol>
```

This is not available for `zksync` also make sure to have the  `RPC_URL` of the chain specified in your `.env` file

- To deploy to a forked network
  
  Use the same command as `deploy-local`

### Using the Factory

The factory deployed at the address: `...`` in most EVM chains, allows you to deterministically deploy a paymaster contract on the same address across different chains. except for zkEVMs with native account abstraction.
Using [Foundry's cast](https://book.getfoundry.sh/cast/) or [zkCast from foundry-zksync](https://github.com/matter-labs/foundry-zksync), you can deploy a paymaster from the factory.

> make sure you have your private key.

To use the Factory:

```sh
# admin: the validation address
# salt: the deployment salt
# choice: 1 or 2 (general or approval based paymaster)
make factory-deploy chain=<chain> admin=<admin address> salt=<deployment salt>
```

example: `make factory-deploy chain=BSC admin=0xB8AF7Fa3DBF5D0c557b6b6dC874c3CC85B0E8d95 salt=21`. Note salted deployments are not available on chains without the `CREATE2` factory.

## Security

This framework comes with slither parameters, a popular security framework from [Trail of Bits](https://www.trailofbits.com/). To use Slither, you'll first need to [install Python](https://www.python.org/downloads/) and [install Slither](https://github.com/crytic/slither#how-to-install).

Optionally update the [slither.config.json](./packages/evm/slither.config.json)

Then, run:

```sh
# always specify a target if you are running `make` from the root folder
make slither
or 
pnpm slither
```
