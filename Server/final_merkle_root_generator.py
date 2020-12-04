
import merkletools
from hashlib import sha256
import sys



# print(merkletools)
mt = merkletools.MerkleTools(hash_type="SHA256")  # default is sha256
# valid hashTypes include all crypto hash algorithms
# such as 'MD5', 'SHA1', 'SHA224', 'SHA256', 'SHA384', 'SHA512'
# as well as the SHA3 family of algorithms
# including 'SHA3-224', 'SHA3-256', 'SHA3-384', and 'SHA3-512'


# print(mt)

file_name = sys.argv[1]
read_file = open(file_name, "r")

all_item_read = read_file.read()

list_data = all_item_read.split("\n")
del list_data[-1]
#print(list_data)

mt.add_leaf(list_data, True)
leaf_count = mt.get_leaf_count()
print("leaf_count = ", leaf_count)

#leaf_value = mt.get_leaf(79)
#print("leaf_value = ", leaf_value)

mt.make_tree() # generates merkle tree
#is_ready = mt.is_ready
#print(is_ready)

root_value = mt.get_merkle_root()
print("root_value = ",root_value)
#proof = mt.get_proof(5)
#print (list_data[5])
#print(proof)

#target_hash = mt.get_leaf(18)
#print(target_hash)

#print(mt.validate_proof(proof,target_hash,root_value))
#print (mt.validate_proof(mt.get_proof(1), mt.get_leaf(1), mt.get_merkle_root()))
final_file_name = "commited_result_to_SC"+".txt"
final_file_path = "output_files\\"+final_file_name
final_file = open(final_file_path, "a")
final_file.write("Merkle root= ")
final_file.write(root_value)
final_file.write("\n")
final_file.close()

