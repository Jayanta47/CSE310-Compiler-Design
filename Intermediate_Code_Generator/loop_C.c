#include<stdio.h>
int main(){
    int a,b,i;
    b=0;
    for(i=0;i<4;i++){
        a=3;
        while(a=a-1){
            b++;
        }
    }
    printf("%d\n", a);
    printf("%d\n", b);
    printf("%d\n", i);
}
