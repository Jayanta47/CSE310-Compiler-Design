for filename in input*.txt
do
	name=$(cut -d'.' -f1<<<$filename)
	number=${name: -1}
	./a.out "$filename" "log$number.txt" "error$number.txt"
	if [[ -d $number ]]
       	then
		echo "Removing Folder $number"
		rm -rf $number
	fi
	mkdir $number
	mv "log$number.txt" $number;
	mv "error$number.txt" $number;
	echo "Execution successful for $filename"
done
