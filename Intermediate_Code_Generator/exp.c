int main(){
    int a,b,c[3], d;
    int e;
    e = 12*4*2;
    printf(e); // 96
    d = 5;
    a=4*(2+3)%3;
    printf(a); // 2
    b= 1<5;
    printf(b); // 1
    b = 2>=3&&2!=4;
    printf(b); // 0
    b = !b;
    printf(b); // 1
    d--;
    printf(d); // 4
    d++;
    printf(d); // 5
    c[2] = d+10;
    a = c[2];
    printf(a); // 15
    c[0]=2;
    if(a && b) {
      c[0]++;
      c[1] = 8;
    }
    else
        c[1]=c[0];

    a = c[0];
    b = c[1];
    printf(a); // 3
    printf(b); // 8

    if(a || 0)
    {
      if ((2&&c[1])||(c[1]&&a))
      {
        printf(a);// 3
      }
      if (50&&0)
      {
        printf(a); // not to be printed
      }
    }

}
