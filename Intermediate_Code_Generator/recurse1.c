int sum(int n)
{
	if (n==0) return 0;
	return n+sum(n-1);
}
int main()
{
	int a;
	a = sum(5);
	printf(a);
}
