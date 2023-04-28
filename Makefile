-include .env

.PHONY: all test clean deploy-anvil

all: yarn clean remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf lib && rm -rf .git/modules/*

install :; forge install smartcontractkit/chainlink-brownie-contracts foundry-rs/forge-std openzeppelin/openzeppelin-contracts redstone-finance/redstone-oracles-monorepo omurovec/foundry-zksync-era --no-commit

yarn :; yarn

# Update Dependencies
update:; forge update

build:; forge build --build-info

test :; forge test

snapshot :; forge snapshot

slither :; forge clean && make build && slither .

myth :; myth analyze ./src/Base.sol --solc-json mythril.config.json --solv 0.8.15 --max-depth 20

format :; prettier --write src/**/*.sol && prettier --write src/**/**/*.sol

# solhint should be installed globally
lint :; solhint src/**/*.sol && solhint src/*.sol

anvil :; anvil -m 'test test test test test test test test test test test junk'

anvil-fork :; anvil --fork-url ${RPC_URL} -m 'test test test test test test test test test test test junk'

# use the "@" to hide the command from your shell 
deploy-goerli :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${GOERLI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv

# use the "@" to hide the command from your shell 
deploy-evmos :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast  -vvvv

# use the "@" to hide the command from your shell 
deploy-evmos-fork :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast 

deploy-all :; make deploy-${network} contract=APIConsumer && make deploy-${network} contract=KeepersCounter && make deploy-${network} contract=PriceFeedConsumer && make deploy-${network} contract=VRFConsumerV2

deploy-pf :; yarn hardhat deploy-zksync --network eraTestnet

verify-pf :; yarn hardhat verify --network eraTestnet ${contract}