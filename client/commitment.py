#!/usr/bin/env python
from sys import argv
from hashlib import sha256
from random import getrandbits

print ("Generating Commitment...")
#read_file = open("delegated_program.bin","r")
read_file = open("input_to_program.txt","r")
input_data = read_file.read()
#print (input_data)


runtime_code_file = open("add.bin-runtime","r")
runtime_code = runtime_code_file.read()

write_file = open("for_server.txt","a")
sc_file = open("for_smart_contract.txt","a")

def main():
    if argv[1] == 'commit':
        msg = input_data 
        key = "{0:0{1}x}".format(getrandbits(256), 64) 
        #print(len(key))
        #write_file.write("key: ")
        ##write_file.write("\n")
        write_file.write("program: ")
        write_file.write("\n")
        write_file.write(runtime_code)
        write_file.write("\n")

        
        com = hashing(key + msg)
        write_file.write("input to program: ")
        write_file.write("\n")
        write_file.write(input_data)
        write_file.write("\n")
        write_file.write("Com_Key_x: ")
        write_file.write("\n")
        write_file.write(key)
        #write_file.write("\n")


        #print("com: %s length: %i" % (com, len(com)))
        #print("key: %s length: %i" % (key, len(key)))

        sc_file.write("com_input: ")
        sc_file.write(com)
        sc_file.write("\n")
        sc_file.write("program: ")
        sc_file.write(runtime_code)
        #sc_file.write("\n")
        #sc_file.write("com_key= ")
        #sc_file.write(key)
        #sc_file.write("\n")

    if argv[1] == 'verify':
        com = argv[2]
        key = argv[3]        
        msg = all_item_read 
        print(com == hashing(key + msg))

def hashing(value):
    encoded_value = value.encode()
    #print(sha256(encoded_value).hexdigest())
    return sha256(encoded_value).hexdigest()

if __name__ == "__main__":
    main()

