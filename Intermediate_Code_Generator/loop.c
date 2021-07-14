int main(){
    int a,b,i;
    b=0;
    for(i=0;i<4;i++){
        a=3;
        while(a--){
            b++;
        }
    }
    printf(a); // -1
    printf(b); // 12
    printf(i); // 4

    int j;
    for(i = 1; i <=4; i++)
    {
      for (j=1;j<=4;j++)
      {
        a = i*j;
        println(a);
      }
    }
}
