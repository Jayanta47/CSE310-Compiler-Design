bison -d -y -v 1705047.y
echo "Bison File produced"
g++ -w -c -o y.o y.tab.c
flex -o ./lex.yy.c ./1705047.l
g++ -w -c -o l.o lex.yy.c
echo "lex file compiled and output created"
echo "Creating linker"
g++ ./y.o ./l.o -lfl 
./a.out input1.txt log1.txt error1.txt
