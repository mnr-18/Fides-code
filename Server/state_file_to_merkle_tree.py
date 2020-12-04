

import merkletools

import hashlib

import sys


file_name = sys.argv[1]
#index = sys.argv[2]


read_file = open(file_name, "r")

all_item_read = read_file.read()

list_data = all_item_read.split("\n")

# print(len(list_data))
# print(list_data)


final_merkle_tree_nodes = list()

for i in range(len(list_data)):

    stack_list = list()
    mem_list = list()
    storage_list = list()
    pc_list = list()

    stack_data = list()
    mem_data = list()
    storage_data = list()
    pc_data = 0


    if "PC" in list_data[i]:
        pc_list = list_data[i].split(" ")
        pc_list[1] = pc_list[1].replace(":","")
        pc_data = pc_list[1]
		

        pc_hash_value = hashlib.sha256(pc_data.encode('utf-8')).hexdigest()
        print("pc_hash_value = ", pc_data)

        final_merkle_tree_nodes.append(pc_hash_value)





    if "STACK" in list_data[i]:
    	stack_list = list_data[i].split("=")
    	stack_list[1] = int(stack_list[1])
    	counter = i + 1

    	if stack_list[1] != 0:
    		
    		
    		while "MEM" not in list_data[counter]:
    		#while counter < i + stack_list[1]:
    			stack_data.append(list_data[counter])
    			counter = counter + 1

    		# print("stack_data = ", stack_data)


    		s_t = merkletools.MerkleTools(hash_type="SHA256")

    		s_t.add_leaf(stack_data, True)
    		stack_leaf_count = s_t.get_leaf_count()
    		s_t.make_tree()

    		is_ready = s_t.is_ready


    		stack_root_value = s_t.get_merkle_root()

    		print("stack_merkle_root = ", stack_root_value)

    		final_merkle_tree_nodes.append(stack_root_value)

    	else:
    		stack_hash_value = hashlib.sha256("STACK=0".encode('utf-8')).hexdigest()
    		print("stack_hash_value = ", stack_hash_value)

    		final_merkle_tree_nodes.append(stack_hash_value)



    if "MEM" in list_data[i]:
    	mem_list = list_data[i].split("=")
    	mem_list[1] = int(mem_list[1])


    	counter = i + 1

    	if mem_list[1] != 0:
    		
    		while "STORAGE" not in list_data[counter]:
    		#while counter < i + mem_list[1]:
    			mem_data.append(list_data[counter])
    			counter = counter + 1

    		# print("mem_data = ", mem_data)

    		m_t = merkletools.MerkleTools(hash_type="SHA256")

    		m_t.add_leaf(mem_data, True)
    		mem_leaf_count = m_t.get_leaf_count()
    		m_t.make_tree()

    		is_ready = m_t.is_ready


    		mem_root_value = m_t.get_merkle_root()

    		print("mem_merkle_root = ", mem_root_value)

    		final_merkle_tree_nodes.append(mem_root_value)

    	else:
    			mem_hash_value = hashlib.sha256("MEM=0".encode('utf-8')).hexdigest()
    			print("mem_hash_value = ",mem_hash_value)

    			final_merkle_tree_nodes.append(mem_hash_value)



    if "STORAGE" in list_data[i]:
    	storage_list = list_data[i].split("=")
    	storage_list[1] = int(storage_list[1])
    	

    	counter = i + 1
    	

    	if storage_list[1] != 0:
    	
    		
    		# while counter < len(list_data):
    		while counter < i + storage_list[1]:
    			storage_data.append(list_data[counter])
    			counter = counter + 1

    		# print("storage_data = ", storage_data)

    		storage_t = merkletools.MerkleTools(hash_type="SHA256")

    		storage_t.add_leaf(storage_data, True)
    		storage_leaf_count = storage_t.get_leaf_count()
    		storage_t.make_tree()

    		is_ready = storage_t.is_ready


    		storage_root_value = storage_t.get_merkle_root()

    		print("storage_merkle_root = ", storage_root_value)
    		final_merkle_tree_nodes.append(storage_root_value)

    	else:
    		storage_hash_value = hashlib.sha256("STORAGE=0".encode('utf-8')).hexdigest()
    		print("storage_hash_value = ",storage_hash_value)

    		final_merkle_tree_nodes.append(storage_hash_value)






f_t = merkletools.MerkleTools(hash_type="SHA256")

f_t.add_leaf(final_merkle_tree_nodes, True)
final_leaf_count = f_t.get_leaf_count()


f_t.make_tree()

is_ready = f_t.is_ready

final_root_value = f_t.get_merkle_root()

final_output = "Final_root_value = " + str(final_root_value)
print(final_output)

final_file_name = "Hash_of_reduced_configuration.txt"
final_file_path = "output_files\\"+final_file_name
write_file = open(final_file_path, "w")
write_file.write(final_output)
write_file.close()

for_Mtree_filename = "RC_array_data.txt"
mtree_file = open(for_Mtree_filename, "a")
mtree_file.write(final_root_value)
mtree_file.write("\n")
mtree_file.close()











