#include<iostream>
#include<string>
using namespace std;

int main()
{
	string Y = R"( My 
	multiline 
	string)";
	cout<<Y<<endl;
	string X = "another\
		    multiline\
		    string";
	cout<<X<<endl;
		    
}
