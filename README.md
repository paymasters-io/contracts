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

**[paymasters.io](https://paymasters.io)** leverages account abstraction to provide the infrastructure from which users can pay for user operations (tx) in a decentralized manner. It is a **gas abstraction** layer that allows users to pay for transactions in any ERC20 token.

[Build](#getting-started) •
[Test](#testing) •
[Report a bug](https://github.com/paymasters-io/contracts/issues/new?assignees=&labels=bug&template=01_BUG_REPORT.md&title=bug%3A+)
• [Questions](https://t.me/paymasters_io)

</div>

**[paymasters.io](https://paymasters.io)** core contract implementation supports the following:

### Off-Chain Identifier

Each paymaster has a unique identifier that is used to identify it off-chain. This identifier is used to identify the paymaster in the paymaster registry.

### Access Control

**[paymasters.io](https://paymasters.io)** core contract uses a **schema-based** approach.

It uses a **role-based** access control system to manage access to the core contract functions.

- ERC20 gating
- nonce limiting
- NFT gating

### Validators

A validator is an **account** that is allowed to sign user operations. Validators are used to verify user operations before they are submitted on-chain.

the validators:

- preview user operations before signing
- sign user-Ops
- re-route delegated operations to the correct paymaster
- check if a delegate is a valid paymaster
- checks if a delegate can pay

#### more on delegates

> **delegates** are just paymasters (they help achieve interoperability between paymasters). we see paymasters as a family of contracts that can be used together to achieve a specific use case. therefore, a delegate is a paymaster that can sponsor transactions for another paymaster (or known sibling).

The dynamic nature of delegation, allows a delegator contract to implement custom logic that can be handled at validation time.
The [IDelegator interface](./src/interfaces/IDelegator.sol) can enable both paymaster interoperability and contract hook programming.

### Signature Verification

**[paymasters.io](https://paymasters.io)** uses 3 signature verification paths

`0-of-2 (ERC20 Paymaster)`: When no signature is required, the paymaster functions as an ERC20 paymaster.

`1-of-2 (Verifying paymaster)`: Signature corresponding to the VALIDATOR must be present in the paymasterData.

`2-of-2 (Verifying paymaster with 2FA)`: Signature corresponding to the VALIDATOR and an external signer must be present in the paymasterData.

  > **Validation address (vaa)**: A paymaster admin;

# Getting Started

## Requirements

Please install the following:

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)  
- [PNPM](https://pnpm.io/installation)
- [Foundry / Foundryup](https://github.com/gakonst/foundry)
  - This will install `forge`, `cast`, and `anvil`
  - You can run: `forge --version` to verify your installation
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

3. Install dependencies

  ```sh
  make install 
  ```

4. To run commands for zkSync-era use: `zk-forge` instead of `forge`. For example:

  ```sh
  zk-forge compile
  # or
  pnpm compile:zk
  ```

note: you must set an alias for `zk-forge` to work. there are some available bash scripts you can use with zkSync-foundry.

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

if your chain does not support [EIP1559](https://eips.ethereum.org/EIPS/eip-1559) transactions, you can use the legacy deployment script

```sh
make deploy-legacy chain=<chain symbol> contract=<contract name>
or
pnpm deploy-legacy chain=<chain symbol> contract=<contract name>
```

example: `make deploy chain=BSC contract=Paymaster`

This will run the following inside the specified target

deploying on zkSync, you need to manually run zk-forge

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

This is not available for `zkSync` also make sure to have the  `RPC_URL` of the chain specified in your `.env` file

- To deploy to a forked network
  
  Use the same command as `deploy-local`

<!-- ### Using the Factory

The factory deployed at the address: `...`` in most EVM chains, allows you to deterministically deploy a paymaster contract on the same address across different chains. except for zkEVMs with native account abstraction.
Using [Foundry's cast](https://book.getfoundry.sh/cast/) or [zkCast from Foundry-zkSync](https://github.com/matter-labs/foundry-zksync), you can deploy a paymaster from the factory.

> make sure you have your private key.

To use the Factory:

```sh
# admin: the validation address
# salt: the deployment salt
# choice: 1 or 2 (general or approval based paymaster)
make factory-deploy chain=<chain> admin=<admin address> salt=<deployment salt>
```

example: `make factory-deploy chain=BSC admin=0xB8AF7Fa3DBF5D0c557b6b6dC874c3CC85B0E8d95 salt=21`. Note salted deployments are not available on chains without the `CREATE2` factory. -->

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
