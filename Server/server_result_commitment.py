#!/usr/bin/env python
from sys import argv
from hashlib import sha256
from random import getrandbits

print ("Generating Commitment...")
read_file_path = "output_files\\"+"final_result.txt"
read_file = open(read_file_path,"r")
all_item_read = read_file.read()
read_file.close()
#print (all_item_read)

m_file_name = "mroot_data"+".txt"
m_file_path = "output_files\\"+m_file_name
m_file = open(m_file_path, "r")
item_read = m_file.read()
list_data = item_read.split("\n")

write_file_path = "output_files\\"+"commited_result_to_SC.txt"
final_file = open(write_file_path,"a")
reveal_data_file_path = "output_files\\"+"reveal_result_to_SC.txt"
reveal_data_file = open(reveal_data_file_path,"w")

def main():
    if argv[1] == 'commit':
        msg = all_item_read 
        #key = "{0:0{1}x}".format(getrandbits(256), 64)
        key = list_data[1] 
        #print(len(key))
        reveal_data_file.write("key= ")
        #write_file.write("\n")
        reveal_data_file.write(key)
        reveal_data_file.write("\n")
        #reveal_data_file.write("output= ")
        reveal_data_file.write(msg)
        reveal_data_file.write("\n")
        
        com = hashing(key + msg)
        #write_file.write("com: ")
        ##write_file.write("\n")
        #write_file.write(com)
        #write_file.write("\n")

        #print("com: %s length: %i" % (com, len(com)))
        #print("key: %s length: %i" % (key, len(key)))

        final_file.write("com= ")
        final_file.write(com)
        final_file.write("\n")
        #sc_file.write("com_key= ")
        #sc_file.write(key)
        #sc_file.write("\n")

    #if argv[1] == 'verify':
        #com = argv[2]
        #key = argv[3]        
        #msg = all_item_read 
        #print(com == hashing(key + msg))

def hashing(value):
    encoded_value = value.encode()
    #print(sha256(encoded_value).hexdigest())
    return sha256(encoded_value).hexdigest()

if __name__ == "__main__":
    main()

