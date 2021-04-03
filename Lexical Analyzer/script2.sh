flex -o lexer.cpp lexer.l
g++ lexer.cpp -lfl -o lexer.out
./lexer.out inputS.txt logS.txt tokenS.txt
