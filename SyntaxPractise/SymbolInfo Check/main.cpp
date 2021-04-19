#include<iostream>
#include<vector>
using namespace std;
#include "1705047_SymbolInfo.h"

int main() {
	param *p = new param;
	p->param_name = "j";
	p->param_type = "int";
	cout<<p->param_type<<" "<<p->param_name<<endl;
	cout<<"Funtion"<<endl;
	vector<param*> vp;
	vp.push_back(p);
	p = new param;
	p->param_name = "str";
	p->param_type = "string";
	vp.push_back(p);
	p = new param;
	p->param_name = "k";
	p->param_type = "int";
	vp.push_back(p);
	for(auto e : vp)
	{
		cout<<e->param_name<<" "<<e->param_type<<endl;
	}
	symbolInfo *s = new symbolInfo("vent", "INT");
	cout<<"symbolInfo Initiated"<<endl;
	cout<<s->getName()<<" "<<s->getType()<<endl;
	if (s->funcPtr == nullptr){
		cout<<"function pointer in symbolInfo is empty"<<endl;
	
	}
	functionInfo *f = new functionInfo;
	f->returnType = "int";
	f->n_params = 2;
	f->param_list = vp;
	cout<<"FuntionInfo initiated and paramlist assigned"<<endl;
	s->funcPtr = f;
	if (s->funcPtr == nullptr){
		cout<<"function pointer in symbolInfo is empty"<<endl;
	
	}
	else {
		cout<<"function pointer assigned properly"<<endl;
	}
	cout<<"Showing symbol info props\n\n";
	for(auto e : s->funcPtr->param_list)
	{
		cout<<e->param_name<<" "<<e->param_type<<endl;
	}
	cout<<"Param size: "<<s->funcPtr->param_list.size()<<endl;

	
}
