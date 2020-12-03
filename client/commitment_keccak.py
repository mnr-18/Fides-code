#!/usr/bin/env python
from sys import argv
from hashlib import sha256
from random import getrandbits
from Crypto.Hash import keccak

print ("Generating Commitment...")
read_file = open("delegated_program.bin","r")
all_item_read = read_file.read()
#print (all_item_read)

write_file = open("commitment_data.txt","w")
sc_file = open("for_smart_contract.txt","a")

def main():
    if argv[1] == 'commit':
        msg = all_item_read    
        key = "{0:0{1}x}".format(getrandbits(256), 64) 
        #print(len(key))
        write_file.write("key: ")
        ##write_file.write("\n")
        write_file.write(key)
        #write_file.write("\n")
        
        com = hashing(key + msg)
        com1 = Keccak_hashing(key + msg)
        #write_file.write("com: ")
        ##write_file.write("\n")
        #write_file.write(com)
        #write_file.write("\n")

        print("com: %s length: %i" % (com, len(com)))
        print("key: %s length: %i" % (key, len(key)))

        print("com1: %s length: %i" % (com1, len(com1)))
        print("key: %s length: %i" % (key, len(key)))

        sc_file.write("com= ")
        sc_file.write(com)
        sc_file.write("\n")
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

def Keccak_hashing(value):
    keccak_hash = keccak.new(digest_bits=256)
    #keccak_hash.update('age')
    keccak_hash.update(value)
    return keccak_hash.hexdigest()

if __name__ == "__main__":
    main()

