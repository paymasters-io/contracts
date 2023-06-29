-include .env

.PHONY: all test clean install update build

all: remove clean install build test

remove :; @rm -rf lib && rm -rf .git/modules/*

clean  :; @forge clean

install :; @forge install foundry-rs/forge-std eth-infinitism/account-abstraction openzeppelin/openzeppelin-contracts openzeppelin/openzeppelin-contracts-upgradeable  matter-labs/era-system-contracts smartcontractkit/chainlink-brownie-contracts redstone-finance/redstone-oracles-monorepo axelarnetwork/axelar-gmp-sdk-solidity --no-commit

update:; @forge update

update-needed:; @forge update lib/redstone-oracles-monorepo

build:; @forge build --build-info --sizes

test :; @forge test --gas-report -vvv

coverage :; @forge coverage -vv

snapshot :; @forge snapshot

slither :; @forge clean && make build && slither .

format :; @prettier --write src/**/*.sol && prettier --write src/**/**/*.sol

lint :; @solhint src/**/*.sol && solhint src/*.sol

deploy :; @forge script script/${contract}.s.sol:Deploy${contract}Script --rpc-url ${$(CHAIN)_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vv

deploy-legacy :; @forge script script/${contract}.s.sol:Deploy${contract}Script --rpc-url ${$(CHAIN)_RPC_URL}  --private-key ${PRIVATE_KEY} --legacy --broadcast -vvv