int main(){
    int a,b,c[3];
    a=1*(2+3)%3;
    printf(a);
    b= 1<5;
    printf(b);
    c[0]=2;
    if(a && b)
        c[0]++;
    else
        c[1]=c[0];
	
    a = c[0];
    b = c[1];
    printf(a);
    printf(b);
}
