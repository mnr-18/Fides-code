
import opcode_values
import re

read_file = open("output_addition.txt","r")

# read_file = open("output.txt","r")

all_item_read = read_file.read()


item_list = all_item_read.split("\n")

# print(all_item_read)
# print(len(item_list[5]))


for i in range(0,len(item_list)):
	if len(item_list[i]) == 0:
		item_list[i] = "None"



# print(item_list)

#########################################
# counter = 0

# label_pattern = ":label[0-9]"

# while (counter <len(item_list)):
# 	if "Stack" in item_list[counter]:
# 		print(item_list[counter])
# 		counter+=1
# 		continue
		
		

# 	if re.match(label_pattern,item_list[counter]):
# 		print(item_list[counter])
# 		counter+=1
# 		continue

# 	code = ""

# 	while (item_list[counter] != "None"):
# 		# print(item_list[counter])		
# 		for key in opcode_values.opcode_dict.keys():
# 			if  re.match(key,item_list[counter]):
# 			# if key in item_list[counter]:
# 				code = code + opcode_values.opcode_dict[key]
			
# 		counter+=1

# 	print("code = ",code, " \n")

# 	counter+=1

###################################

pattern = "0x"
counter = 0

write_file = open("final_output.txt","w")

while (counter <len(item_list)):
	if "block_" in item_list[counter]:
		if counter != 0:
			write_file.write("\n")
		write_file.write(item_list[counter])
		write_file.write("\n")
		print(item_list[counter])
		counter = counter + 1
		continue

	code = ""

	while item_list[counter] != "None":
		# print(item_list[counter])
		if pattern in item_list[counter]:
			# print(item_list[counter])
			ss_lists = item_list[counter].split("\t\t")

			number = ss_lists[1]
			number = number.replace("0x","")
			# print(number)

			ss_lists = [ss_lists[0],number]

			# for ss in range(0,len(ss_lists)):
			# 	number = ss_lists[ss][1]
			# 	# print(number)
			# 	number = number.replace("0x","")
				# ss_lists[ss] = number
			# print(ss_lists) 
			for key in opcode_values.opcode_dict.keys():
				if key == ss_lists[0]:
					code = code + str(opcode_values.opcode_dict[key])+str(ss_lists[1])
					break
				else:
					continue

		else:

			for key in opcode_values.opcode_dict.keys():
				if key == item_list[counter]:
					code = code + opcode_values.opcode_dict[key]

				else:
					continue


		counter = counter + 1

	print("code = ",code)

	final_code = "code = "+ str(code)
	write_file.write(final_code)
	write_file.write("\n")
	counter = counter + 1






