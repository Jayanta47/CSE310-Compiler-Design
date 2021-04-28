#include<iostream>
#include<regex>
#include<string>

using namespace std;

int main()
{
	std::regex b("[0-9]+");
	std::string str;
       	while(1)
	{
		cout<<"Insert string \n";
		cin>>str;
		if (str=="q") break;
		if (std::regex_match(str, b)) cout<<"match\n";
		else cout<<"No Match\n";
	}
	return 0;	
}

