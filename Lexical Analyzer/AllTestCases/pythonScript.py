import os
import sys
import shutil

fileName = str(sys.argv[1]).split("/")[-1]
fileName = fileName.split(".")[0]
print(fileName)
if os.path.exists(fileName):
	shutil.rmtree(fileName)
os.mkdir(fileName)
shutil.move("./1705047_log.txt","./" + fileName)
shutil.move("./1705047_token.txt","./" + fileName)


	
