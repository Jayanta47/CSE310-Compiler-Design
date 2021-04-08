for file in ./*.txt;
do 
./lexer.out ${file}
python3 pythonScript.py ${file}
done;

