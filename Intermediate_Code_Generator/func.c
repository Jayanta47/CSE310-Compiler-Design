int d;
int f(int a){
    return 2*a;
    a=9;
}

int g(int a, int b){
    int x;
    x=f(a)+a+b;
    return x;
}

void h()
{
  d = d*5;
}

int main(){
    int a,b;
    d = 5;
    a=1;
    b=2;
    a=g(a,b);
    h();
    printf(a); // 5
    printf(d); // 25
    return 0;
}
