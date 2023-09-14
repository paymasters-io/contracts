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

Visit our website: [paymasters.io](https://paymasters.io) • Questions: [Telegram](https://t.me/paymasters_io) • Report a bug: [GitHub](https://github.com/paymasters-io/contracts/issues/new?assignees=&labels=bug&template=01_BUG_REPORT.md&title=bug%3A+)

At **[paymasters.io](https://paymasters.io)**, we are enabling a robust infrastructure that allows you to seamlessly pay for Ethereum transaction fees.
</div>

## ERC20 Paymaster (Multi-Token Standard)

Our ERC20 Paymaster sets the gold standard for gas abstraction. With this contract, users can pay for transactions using a wide array of ERC20 tokens. The flexibility of this paymaster enables transactions to be settled using any accepted ERC20 token

## Modular Paymaster

Introducing the Modular Paymaster - a concept that opens doors to innovation. This contract empowers users to define custom modules for our verifying paymaster validation. You can now focus solely on your business logic, while we handle the intricate gas abstraction layer for your users.

### Modules examples

1. ERC20 Gating Module
2. NFT Gating Module
3. OnChain Rebates Module
4. Human Verification Module

...and more.

### Validation Process

To ensure reliability, every module undergoes an attestation process:

1. **Module Interface Implementation**: A module must adhere to the [IModule Interface](./src/interfaces/IModule.sol) for compatibility.
2. **Registration and Attestation**: Modules need to be registered and attested by trusted entities in [EAS](https://easscan.org/), for transparency and integrity.
3. **Registration Fee**: A non-refundable registration fee is required.
4. **Threshold Requirement**: Modules must meet a minimum threshold of attesters for acceptance.
5. **Revocation Handling**: Modules can be rejected if any attestor revokes their attestation.
6. **Safety Review**: Following attestation, a mandatory **1-DAY** delay occurs before module approval.
7. Mudules can skip the attestation process, if they are not handling post operations.

# Getting Started

## Requirements

Please install the following:

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)  
- [PNPM](https://pnpm.io/installation)
- [Foundry](https://github.com/gakonst/foundry)
- [make](https://askubuntu.com/questions/161104/how-do-i-install-make)

## Quick Start

1. First, clone the repo

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

4. compile the contracts

  ```sh
  pnpm compile
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
- `<CHAIN>_RPC_URL`: most of the chains are pre-filled with a free RPC provider URL.
- Also, you need to hold some Testnet tokens in the chain you are deploying to.

### Deploying

```sh
make deploy chain=<chain symbol> contract=<contract name>
# or 
pnpm deploy chain=<chain symbol> contract=<contract name>
```

If your chain does not support [EIP1559](https://eips.ethereum.org/EIPS/eip-1559) transactions, you can use the legacy deployment script

```sh
make deploy-legacy chain=<chain symbol> contract=<contract name>
# or
pnpm deploy-legacy chain=<chain symbol> contract=<contract name>
```

example: `make deploy chain=BSC contract=Paymaster`

This will run the following inside the specified target

```sh
# eip1559 supported chains
forge script script/${contract}.s.sol:Deploy${contract} --rpc-url $${$(CHAIN)_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vv
# legacy chains
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

- To deploy to a forked network
  
  Use the same command as `deploy-local`

## Security

This framework comes with slither parameters, a popular security framework from [Trail of Bits](https://www.trailofbits.com/). To use Slither, you'll first need to [install Python](https://www.python.org/downloads/) and [install Slither](https://github.com/crytic/slither#how-to-install).

Optionally update the [slither.config.json](./packages/evm/slither.config.json)

Then, run:

```sh
make slither
# or
pnpm slither
```
