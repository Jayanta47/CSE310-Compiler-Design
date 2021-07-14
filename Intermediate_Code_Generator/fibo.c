int fibo(int n)
{
	if (n<=0)
	{
		return 0;
	}
	if (n==1)
	{
		return 1;
	}
	return fibo(n-1)+fibo(n-2);
}

void main()
{
	int a;
	a = fibo(0); // 0
	printf(a);
	a = fibo(1); // 1
	printf(a);
	a = fibo(2); // 1
	printf(a);
	a = fibo(5); // 5
	printf(a);
	a = fibo(6); // 8
	printf(a);
	a = fibo(8); // 21
	printf(a);
}
