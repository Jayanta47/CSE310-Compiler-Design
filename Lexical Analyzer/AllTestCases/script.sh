for file in ./*.txt;
do 
./submitLexer.out ${file}
python3 pythonScript.py ${file}
done;

