

import opcode_values
import re

read_file = open("output.txt","r")

all_item_read = read_file.read()


item_list = all_item_read.split("\n")

del item_list[:4]


for i in item_list:
	if len(i)==0:
		item_list.remove(i)

# for i in item_list:
# 	print(i)

file_name_counter = 0
#print(len(item_list))
for i in range(len(item_list)):
	counter = 0
	if "PC" in item_list[i]:

		state_file_name = "rc_"+ str(file_name_counter)+".txt"
		file_name_counter = file_name_counter + 1

		state_file_path = "reduced_configurations\\"+state_file_name

		write_file = open(state_file_path, "w")




		pc_list = item_list[i].split(" ")
		del pc_list [3:]
		# print(pc_list)
		pc_line = pc_list[0] + " "+ pc_list[1]
		instruction_opcode = pc_list[2]
		# print(instruction_opcode)
		instruction_value = 0
		if instruction_opcode in opcode_values.opcode_dict.keys():

			instruction_value = opcode_values.opcode_dict[instruction_opcode]

		instruction_line = "Instruction : " + instruction_value

		#print(pc_line)
		#print(instruction_line)

		write_file.write(pc_line)
		write_file.write("\n")
		write_file.write(instruction_line)
		write_file.write("\n")

		counter = i + 1

		# print("i = ",i )
		# print("counter =" , counter)

		while "PC" not in item_list[counter] and i< len(item_list):
			next_items= item_list[counter]
			#print(next_items)
			write_file.write(next_items)
			write_file.write("\n")

			counter = counter +1
			if counter >= len(item_list) - 1:
				break
			# print("loop counter =" , counter)

		write_file.close()
		#print()

	if "OUT" in item_list[i]:

		state_file_name = "final_result"+".txt"
		file_name_counter = file_name_counter + 1

		state_file_path = "output_files\\"+state_file_name

		write_file = open(state_file_path, "w")


		write_file.write(item_list[i])

		#print(item_list[i])
		write_file.close()




	# write_file.close()



