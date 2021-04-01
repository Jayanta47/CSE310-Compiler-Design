flex -o mulCharError.c multicharErr.l
g++ mulCharError.c -lfl -o multiCharError.out
./multiCharError.out multicharErr.txt
