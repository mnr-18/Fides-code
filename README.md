## Fides
A Refereed delegation of computation system using smart contract. 

## How it works
![uml_new](https://user-images.githubusercontent.com/75406127/101208983-39252d80-3630-11eb-94c3-e1ea0d91231a.jpg)

## Required tools
- [Solidity Compiler](https://docs.soliditylang.org/en/v0.5.17/installing-solidity.html): to compile Solidity program.
- [evm-tools](https://github.com/CoinCulture/evm-tools): a collection of tools for working with the evm.
- [Remix](https://remix.ethereum.org/): a browser-based IDE.
- [Ganache](https://www.trufflesuite.com/ganache): personal blockchain for Ethereum application development.

## Fides Functionalities
- [Client](#client)
- [Server](#server)
- [Referee](#referee)


## Client
1. Writes the delegated program  "delegated_program.sol"
2. Compiles "delegated_program.sol" using solc compiler
```
solc --bin-runtime --optimize -o . delegated_program.sol
```
- It will output the runtime bytecode "delegated_program.bin-runtime".
3. Generates commitment to the Input: The input to the delegated program consists of the function id and the input data.

- Get the function id: `solc --hashes delegated_program.sol`
- Generate input to program = (function id || input data): `python3 input generator.py <input_data.txt> <function id>`
- Generate the commitment to input to program: `python3 commitment.py commit`. It will output the commitment value and the commitment key

The above steps (2) and (3) can be run together using the *client.sh* script. To run the *client.sh* file (from Windows using *wsl* or in Ubuntu) use the following commands:
```
chmod +x client.sh
```
```
./client.sh
```


After executing the above operations, the client will send the followings to the smart contract and
to the servers.
- *To referee contract*: The client will send the "delegated_program.bin-runtime" and "commitment_value"
to the referee contract on Blockchain.
- *To servers*: The client will send the "delegated_program.sol", "input_to_program" and "commitment_key" to the servers.

## Server
1. Registers for computation by calling the *Register()* function of the referee contract.
2. Check whether received input is correct or not:
- Generate the commitment to input to program: `python3 commitment.py commit`
- Verify: `python3 commitment.py verify <commitment value> <commitment key>`
3. Check for non-deterministic instructions in program bytecode.
- (using evm-tools run following command): `echo $(cat delegated_program.bin-runtime) | disasm > evm_instructions.txt`
- Then run: `python3 check_determinism.py evm_instructions.txt`

4. Program execution:
- (a) Execute computation and save the intermediate state data into an output file:
`evm --debug --code <delegated_program.binruntime> --input <input_to_program> 2>1 j tee output.txt`
- (b) Generate state files for each intermediate state from the output file: `python3 state_files_creator.py`. It will output the intermediate state files for each state i (*state_i.txt*) and a *final_result.txt* file.
- (c) Generate Merkle tree on reduced-configuration (RC): `python3 merkle_tree_generator.py <hashed_RC.txt>`. It will output *mroot_data.txt* with the Merkle root constructed on RC array.
- (d) Get final root value concatenating Merkle root with server's public key: `python3 final_merkle_root_generator.py <mroot_data.txt>`
- (e) Generate commitment to computation result: `python3 server_result_commitment.py commit`. It will read the value from *final_result.txt* file and output a *commitment_to_result* value.

5. Send the outputs from 4(d), (e) and the length of RC array to the referee contract.
6. (Once the SC asks to reveal result), send the value from *final_result.txt* along with the commitment key to SC.
### (In case of inconsistency)

#### (i) For binary-search:
- Get the hash of the reduced configuration (HRC) and Merkle proof for index j: `python3 state_files_to_merkle_tree.py <state_j.txt>`
- Send the HRC value and the proof the referee contract (using the Brwoser interace for the server).
#### (ii) For single-step execution:
- get Merkle proof for step ng: `python3 state_files_to_merkle_tree.py <state_ng.txt> getProof ng`
- get deployable bytecode

(a) construct state bytecode for ng: `python3 generate_state_bytecode.py <state_ng.txt>`. It will output state bytecode (in state_bytecode.txt) for ng.

(b) construct deployable bytecode by appending constructor code to state bytecode (using evm-tools):
`echo $(cat state bytecode.txt) | evm-deploy > deploy_code.txt`
- Send the data from state_ng.txt, proof for ng, state_nb.txt, and deploy_code.txt to referee smart contract.

## Referee
The referee is a smart contract on the Ethereum blockchain. This contract enforces the verifiable computation algorithm. It also manages
the interactions between the client and the servers. 

### Deploying referee contract
- Start Ganache GUI
- Deploy the referee contract using [Remix](https://remix.ethereum.org/) and set the environment as *Web3 Provider* with Endpoint: http://127.0.0.1:8545 

(see the Deployment instruction in the Referee folder for more details)
### Interacting with referee contract
- *Interaction between server and SC*: Using the browser interface that uses Web3.js library. This library gives Ethereum module for interacting with Ethereum network. (see the setup instruction in Sever/Server_to_SC)
 

