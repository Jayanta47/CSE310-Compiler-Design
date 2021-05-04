#include<bits/stdc++.h>

using namespace std;
int main()
{
	std::vector<pair<string, int>> s;
	s.push_back(make_pair("array", 2));
	
	for(auto x:s)
	{
		cout<<x.first<<" "<<x.second<<endl;
	}

	return 0;
}

