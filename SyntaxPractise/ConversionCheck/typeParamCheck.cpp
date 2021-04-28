#include<iostream>
using namespace std;

void foo(int a, float ,float, int b)
{
	cout<<"inside func foo\n";
}

void foo2(void)
{
	cout<<"Inside foo2\n";
}

int main()
{
	foo(1, 2.5,1.5, 3);
	foo2();
	return 0;
}
