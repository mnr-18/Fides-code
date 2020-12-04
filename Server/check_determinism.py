import sys


file_name = sys.argv[1]

non_det_instruction_list = ["EXTCODESIZE","EXTCODECOPY","BLOCKHASH","COINBASE","TIMESTAMP","NUMBER","DIFFICULTY","CREATE","CREATE2","CALL","DELEGATECALL"]


Non_deterministic = False

with open(file_name) as f:
    for line in f:

        for i in non_det_instruction_list:
            if i in line.strip():
                Non_deterministic = True
                


if Non_deterministic == True:
    print("This is Non-Deterministic")
else:
    print("This is Deterministic")

