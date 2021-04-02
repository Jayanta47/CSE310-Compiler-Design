flex -o lexer.cpp lexer.l
g++ lexer.cpp -lfl -o lexer.out
./lexer.out input2.txt log2.txt token2.txt
./lexer.out input1.txt log1.txt token1.txt
./lexer.out input3.txt log3.txt token3.txt
./lexer.out input4.txt log4.txt token4.txt
./lexer.out input5.txt log5.txt token5.txt

