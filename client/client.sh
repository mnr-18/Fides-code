#!/bin/bash
# Client Script
#task1: compile delegated program (generates program bytecode) 
solc --bin-runtime --optimize -o . add.sol
echo "Program file 'add.bin-runtime' created."
echo $'\n'
#task2: generate input to program
echo "Generating input to program......."
python3 input_generator.py input_data.txt a5f3c23b
echo "Input to program generated."
echo $'\n'
#task3: Commitment generation
# pip3 install pycryptodome
echo "Reading input data......."
chmod +x commitment.py 
python3 commitment.py commit
echo "Commitment to input generated."
echo $'\n'
#task 4: Merkle Tree construction 
#pip3 install merkletools
#chmod +x merkle_tree_generator.py
#python3 merkle_tree_generator.py
#echo "Merkle Tree generated."
