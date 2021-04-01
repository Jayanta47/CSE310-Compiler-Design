flex -o comments.c comments.l
g++ comments.c -lfl -o comments.out
./comments.out comments.txt
