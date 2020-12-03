#!/bin/bash
# Client Script
#task1: compile delegated program (generates program bytecode) 
#   solc --bin --optimaze -o . delegated_program.sol
#task2: generate asm file 
#   solc --asm -o delegated_program.asm delegated_program.sol
#task3: Commitment generation
# pip3 install pycryptodome
chmod +x commitment.py 
python3 commitment.py commit
echo "Commitment generated."
echo $'\n'
#task 4: Merkle Tree construction 
#pip3 install merkletools
chmod +x merkle_tree_generator.py
python3 merkle_tree_generator.py
echo "Merkle Tree generated."