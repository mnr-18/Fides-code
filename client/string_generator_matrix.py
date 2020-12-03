import sys



file_name = sys.argv[1]

hex_string = sys.argv[2]

read_file = open(file_name, "r")

all_item_read = read_file.read()

list_data = all_item_read.split("\n")


# print(list_data)
while("" in list_data) : 
    list_data.remove("") 

# print(list_data)



for i in range (len(list_data)):
        if "[" in list_data[i] and "]"in list_data[i]:
            list_data[i] = list_data[i].replace("[","")
            list_data[i] = list_data[i].replace("]","")
            print(list_data[i])


# print(list_data)
final_output_string_list = list()

final_output_string_list.append(hex_string)




for i in list_data:

    new_list = i.split(",")
    print(new_list)
    for j in new_list:
        length_of_number = len(j)

        total_bit = 64

    

        new_number = j.zfill(total_bit)
        final_output_string_list.append(new_number)


print(final_output_string_list)

final_output_string = ''.join(final_output_string_list)

print(final_output_string)

    
write_file = open("matrix_string_generator_output.txt", "w")

write_file.write(final_output_string)

write_file.close()