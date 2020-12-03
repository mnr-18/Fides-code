import merkletools
#!/usr/bin/env python

sc_file = open("for_smart_contract.txt","a")


print ("Generating Merkle Tree...")
# print(merkletools)
mt = merkletools.MerkleTools(hash_type="SHA256")  # default is sha256
# valid hashTypes include all crypto hash algorithms
# such as 'MD5', 'SHA1', 'SHA224', 'SHA256', 'SHA384', 'SHA512'
# as well as the SHA3 family of algorithms
# including 'SHA3-224', 'SHA3-256', 'SHA3-384', and 'SHA3-512'
# print(mt)

write_file = open("for_server.txt","a")
read_file = open("delegated_program.asm", "r")
all_item_read = read_file.read()
list_data = all_item_read.split("\n")

#print(len(list_data))
#print(list_data)

for i in range (0, len(list_data)):

    if "\t\t" in list_data[i]:
        list_data[i] = list_data[i].replace("\t\t", "")
        # print(list_data[i])

    elif "t" in list_data[i]:
        list_data[i] = list_data[i].replace("\t", "")
    elif " " in list_data[i]:
        list_data[i] = list_data[i].replace(" ", "")

#print("\n\n")
#print(list_data)
write_file.write("program instructions: ")
write_file.write(str(list_data))


mt.add_leaf(list_data, True)
leaf_count = mt.get_leaf_count()
print("leaf_count = ", leaf_count)
# leaf_value = mt.get_leaf(79)
# print("leaf_value = ", leaf_value)

mt.make_tree() # generates merkle tree
is_ready = mt.is_ready
#print(is_ready)

#write_file = open("merkle_root.txt","w")
root_value = mt.get_merkle_root()
print ("Merkle Root generated.")
print("root_value = ",root_value)
#write_file.write("Root value= ")
#write_file.write(root_value)
sc_file.write("root= ")
sc_file.write(root_value)
sc_file.write("\n")


proof = mt.get_proof(1)
#print(proof)
target_hash = mt.get_leaf(1)
#print(mt.validate_proof(proof,target_hash,root_value))
#print (mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root()))
