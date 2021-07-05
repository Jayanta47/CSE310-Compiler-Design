int factorial(int n)
{
	if (n<=1)
	{
		return 1;
	}
	else
	{
		return n*factorial(n-1);
	}
}

int main()
{
	int a;
	a = factorial(1); // 1
	printf(a);
	a = factorial(2); // 2
	printf(a);
	a = factorial(4); // 24
	printf(a);
	a = factorial(5); // 120
	printf(a);
	a = factorial(6); // 720
	printf(a);
	a = factorial(7); // 5040
	printf(a);

}
