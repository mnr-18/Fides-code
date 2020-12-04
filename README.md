## Fides
A Refereed delegation of computation system using smart contract. 

## Required tools
- [Solidity Compiler] (https://docs.soliditylang.org/en/v0.5.17/installing-solidity.html): to compile Solidity program.
- [evm-tools](https://github.com/CoinCulture/evm-tools): a collection of tools for working with the evm.
- [Remix](https://remix.ethereum.org/): a browser-based IDE.

## Fides Functionalities

- [Client](#client)
- [Server](#server)
- [Referee](#referee)


## Client
1. Write the delegated program  "delegated program.sol"
2. Compile "delegated program.sol" using solc compiler
- command: solc --bin-runtime --optimize -o : delegated program.sol
- It will output the runtime bytecode "delegated program.bin-runtime".
3. Generate commitment to the Input: The input to the delegated program consists of the function id and the input data.
- Get the function id: solc --hashes delegated program.sol
- Generate input to program = (function id jj input data):
  python3 input generator.py <input data:txt> <function id>
 Generate the commitment to input to program: python3 commitment.py commit
- It will output the commitment value and the commitment key
After executing the above operations, the client will send the followings to the smart contract and
to the servers.
 To referee contract: The client will send the \delegated program.bin-runtime" and \commitment value"
to the referee contract on Blockchain.
 To servers: The client will send the \delegated program.sol", \input to program" and \com-
mitment key" to the servers.
2 Server
1. Register for computation by calling the Register() function of the referee contract.
2. Check whether received input is correct or not:
 Generate the commitment to input to program: python3 commitment.py commit
 Verify: python3 commitment.py verify <commitment value> <commitment key>
1
Fides
3. Check for non-deterministic instructions in program bytecode.
4. Program execution:
(a) Execute computation and save the intermediate state data into an output file:
evm --debug --code <delegated program:bin􀀀runtime> --input <input to program> 2>
1 j tee output.txt
(b) Generate state files for each intermediate state from the output file:
python3 state files creator.py
- it will output the intermediate state files for each state i (state i:txt) and a final result:txt
file
(c) Generate Merkle tree on reduced-configuration (RC):
python3 merkle tree generator.py <hashed RC:txt>
- outputs mroot data:txt with the Merkle root constructed on RC array.
(d) Get final root value concatenating Merkle root with server's public key:
python3 final merkle root generator.py <mroot data:txt>
(e) Generate commitment to computation result:
python3 server result commitment.py commit
- it will read the value from final result:txt file and out a commitment to result value.
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

