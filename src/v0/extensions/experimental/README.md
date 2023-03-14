# EXPERIMENTAL CONTRACTS

the contracts in this folder are marked as experimental and are not actually advised for implementation or production use yet.
however you can draw inference from work in progress from the contracts in this folder.

## L1 messaging paymaster

this paymaster is being developed to have direct interaction with the ethereum L1 blockchain or any other EVM chain.
as part of the initial proposal, it is meant to check for arbitrary conditions on external chain before settling transactions on L2
however the zkSync evm has not achieved instant finality as the time for a transaction to be accepted in L2 and finalized in L1 takes time.
additional time will be consumed when the L1 blockchain (ethereum) sends its return message back to zkSync.
the process is outlined as:

- L2 -> L1 message
- L1 -> L2 return message

the L1 <-> L2 communication is not happening in a single transaction.

## update

from the proposal above
- the XChain validation paymaster will always settle the initial transaction.
- each transaction will initiate an X-chain message if specified so.
- the response of the X-chain message will be saved and used to validate the next transaction.
- if the response is not received before the next transaction, gas offset is rejected.
- a single X-chain response can be used for a batch of progressive transaction.
- the X-chain message can be renewed after the last transaction in the batch is paid for
- the X-Chain message can periodically validate access in external EVMs. 
- as long as the response remains valid, the Paymaster will offset gas for the user.
