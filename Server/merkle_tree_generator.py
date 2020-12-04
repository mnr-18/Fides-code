
import merkletools
from hashlib import sha256
import sys
from random import getrandbits


# print(merkletools)
mt = merkletools.MerkleTools(hash_type="SHA256")  # default is sha256
# valid hashTypes include all crypto hash algorithms
# such as 'MD5', 'SHA1', 'SHA224', 'SHA256', 'SHA384', 'SHA512'
# as well as the SHA3 family of algorithms
# including 'SHA3-224', 'SHA3-256', 'SHA3-384', and 'SHA3-512'


# print(mt)

file_name = sys.argv[1]
read_file = open(file_name, "r")

#idx_v = sys.argv[2]

all_item_read = read_file.read()

list_data = all_item_read.split("\n")
del list_data[-1]
num_of_reduced_config = len(list_data)
key = "{0:0{1}x}".format(getrandbits(256), 64)
#print("key=",key)
#list_data.insert(len(list_data),key)
print("#of steps=", num_of_reduced_config)
#print(list_data)

mt.add_leaf(list_data, True)
leaf_count = mt.get_leaf_count()
print("leaf_count = ", leaf_count)

#leaf_value = mt.get_leaf(79)
#print("leaf_value = ", leaf_value)

mt.make_tree() # generates merkle tree
is_ready = mt.is_ready
#print(is_ready)

root_value = mt.get_merkle_root()
print("root_value = ",root_value)
idx_v = 10
proof = mt.get_proof(idx_v)
#print (list_data[5])
#print(proof)
#write_proof_file_name = "Hash_of_reduced_configuration.txt"
#write_proof_file_path = "output_files\\"+write_proof_file_name
#write_proof_file = open (write_proof_file_path ,"a")
#write_proof_file.write("\n")
#write_proof_file.write(str(proof))
#write_proof_file.close()

#target_hash = mt.get_leaf(18)
#print(target_hash)

#print(mt.validate_proof(proof,target_hash,root_value))
#print (mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root()))
m_file_name = "mroot_data"+".txt"
m_file_path = "output_files\\"+m_file_name
m_file = open(m_file_path, "w")
m_file.write(root_value)
m_file.write("\n")
m_file.write(key)
m_file.write("\n")
m_file.close()

final_file_name = "commited_result_to_SC"+".txt"
final_file_path = "output_files\\"+final_file_name
final_file = open(final_file_path, "a")
final_file.write("Number of steps=")
final_file.write(str(num_of_reduced_config))
final_file.write("\n")
final_file.close()