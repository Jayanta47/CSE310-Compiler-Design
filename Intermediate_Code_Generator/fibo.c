int fibo(int n)
{
	if (n==2)
	{
		return 1;
	}
	if (n<=1)
	{
		return 0;
	}
	return fibo(n-1)+fibo(n-2);
}

void main()
{
	int a;
	a = fibo(1);
	printf(a);
	a = fibo(2);
	printf(a);
	a = fibo(6);
	printf(a);
	a = fibo(5);
	printf(a);
}


