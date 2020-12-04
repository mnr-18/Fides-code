## Fides
A Refereed delegation of computation system using smart contract. 

## Required tools
- [Solidity Compiler](https://docs.soliditylang.org/en/v0.5.17/installing-solidity.html): to compile Solidity program.
- [evm-tools](https://github.com/CoinCulture/evm-tools): a collection of tools for working with the evm.
- [Remix](https://remix.ethereum.org/): a browser-based IDE.

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
- Generate input to program = (function id || input data): `python input generator.py <input_data.txt> <function id>`
- Generate the commitment to input to program: `python commitment.py commit`. It will output the commitment value and the commitment key

The above steps (2) and (3) can be run together using the *client.sh* script. To run the *client.sh* file (from Windows using *wsl* or in Ubuntu) use the following commands:
```
chmod +x client.sh
```
```
./client.sh
```


After executing the above operations, the client will send the followings to the smart contract and
to the servers.
- *To referee contract*: The client will send the "delegated program.bin-runtime" and "commitment value"
to the referee contract on Blockchain.
- *To servers*: The client will send the "delegated program.sol", "input to program" and "commitment key" to the servers.

## Server
1. Registers for computation by calling the *Register()* function of the referee contract.
2. Check whether received input is correct or not:
- Generate the commitment to input to program: `python commitment.py commit`
- Verify: `python commitment.py verify <commitment value> <commitment key>`
3. Check for non-deterministic instructions in program bytecode.
- (using evm-tools run following command): `echo $(cat delegated_program.bin-runtime) | disasm > evm_instructions.txt`
- Then run: `python3 check_determinism.py evm_instructions.txt`

4. Program execution:
- (a) Execute computation and save the intermediate state data into an output file:
`evm --debug --code <delegated_program.binruntime> --input <input_to_program> 2>1 j tee output.txt`
- (b) Generate state files for each intermediate state from the output file: `python3 state_files_creator.py`. It will output the intermediate state files for each state i (*state i.txt*) and a *final_result.txt* file.
- (c) Generate Merkle tree on reduced-configuration (RC): `python3 merkle_tree_generator.py <hashed_RC.txt>`. It will output *mroot_data.txt* with the Merkle root constructed on RC array.
- (d) Get final root value concatenating Merkle root with server's public key: `python3 final_merkle_root_generator.py <mroot_data.txt>`
- (e) Generate commitment to computation result: `python3 server_result_commitment.py commit`. It will read the value from final result:txt file and out a commitment to result value.

5. Send the outputs from 4(d), (e) and the length of RC array to the referee contract.
6. (Once the SC asks to reveal result), send the value from final result:txt to SC.
(In case of inconsistency)
 For binary-search:
- Get the hash of the reduced configuration and Merkle proof for index j:
python3 state files to merkle tree.py <state j:txt>
 For single-step execution:
(a) get Merkle proof for step ng
python3 state files to merkle tree.py <state ng:txt> getProof ng
(b) get deployable bytecode
(i) construct state bytecode for ng:
python3 generate state bytecode.py <state ng:txt>
- it will output state bytecode (in state bytecode:txt) for ng.
(ii) construct deployable bytecode by appending constructor code to state bytecode
(using evm-tools):
echo $(cat state bytecode.txt) j evm-deploy > deploy code.txt
 Send the data from state ng:txt, proof for ng, state nb:txt, and deploy code:txt to SC.

