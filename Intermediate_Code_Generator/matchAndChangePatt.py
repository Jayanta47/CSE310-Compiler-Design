import re
import sys

assm_code_pattern = "[\t]*A\/[^\n]*" # pattern for assembly language code 


lines_to_change = [] # list to contain the lines to be changed 
indices = [] # list to contain the indices of the lines to be changed

def findOutAssmCodes(read_file_name):
	f = open(read_file_name, "r")
	i = 0
	for line in f:
		i = i + 1
		if re.match(assm_code_pattern, line):
			tabs = line.count("\t")
			line = line.rstrip("\n")
			line = line.split("/")[1]
			line = f"oss<<\"{line}\"<<endl;"
			line = "\t"*tabs + line
			lines_to_change.append(line)
			indices.append(i)
			
	f.close()

def changeAssmCodes(read_file_name, write_file_name):

	f = open(read_file_name, "r")

	fout = open(write_file_name, "w")

	change_list_index = 0
	line_no = 0

	for line in f:
		line_no +=1
		if (change_list_index < len(indices) and line_no == indices[change_list_index]):
			print(f"Line changed, at index: {line_no}, line=> {line} ")
			fout.write(lines_to_change[change_list_index]+"\n")
			change_list_index += 1
		else :
			fout.write(line)
		
	print("total lines read: ", line_no)	
	print("total lines changed: ", len(indices))
	f.close()
	fout.close()


if __name__ == "__main__":
	if len(sys.argv) < 3:
		print("Insufficient number of arguments passed")
		sys.exit()
	read_file_name = sys.argv[1]
	write_file_name = sys.argv[2]
	print("Assembly Code Converter")
	print("__________________________________")
	print("# converting every line with A/[line] format#")
	print(f"Read File = \"{read_file_name}\"")
	print(f"Output to File = \"{write_file_name}\"")
	findOutAssmCodes(read_file_name)
	changeAssmCodes(read_file_name, write_file_name)
	
	

	
