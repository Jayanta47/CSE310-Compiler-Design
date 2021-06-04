for filename in input*.txt # select al input files in current directory
do
	name=$(cut -d'.' -f1<<<$filename) # split the filename with delimeter and take the first portion using f1
	number=$(cut -d't' -f2<<<$name); # split on t and take rest of filename as the number
	./a.out "$filename" "log$number.txt" "error$number.txt" # execute file with executable a.out from bison and produce log and error fie
	if [[ -d $number ]] # if folder with number already exists, remove that
       	then
		echo "Removing Folder $number"
		rm -rf $number
	fi
	# make directory with the number and send log and error files in their respective folders
	mkdir $number
	mv "log$number.txt" $number;
	mv "error$number.txt" $number;
	echo "Execution successful for $filename"
done
