#include<iostream>
#include<cstdlib>
using namespace std;

int main()
{
	string str = "1";
	cout<<str<<endl;
	int i = atoi(str.c_str());
	cout<<"int i = "<<i<<endl;
	str="-1";
	i = atoi(str.c_str());
	cout<<"Neg i ="<<i<<endl;
}
