#include<iostream>
#include<string>
using namespace std;
#include "ScopeTable.h"

using namespace std;

int main()
{
    // symbolInfo *A = new symbolInfo("a", "INTEGER");
    // cout<<A->getName()<<" "<<A->getType()<<" \n";
    // A->setNext(new symbolInfo("b", "float"));
    // symbolInfo *B = A->getNext();
    // B->setPrev(A);
    // cout<<B->getName()<<" "<<B->getType()<<"\n";
    // cout<<B->equalsName("b")<<endl;
    // symbolInfo *C = new symbolInfo("c", "INT");
    // C->setNext(A);
    // A->setPrev(C);

    // delete A;

    // string a = "abcd";
    // for (int i=0;i<a.size(); i++)
    // {
    //     int b = a[i];
    //     cout<<b<<endl;
    // }
    cout<<"Hello World"<<endl;
    ScopeTable *sch = new ScopeTable(6, 1);
    sch->Print();
    cout<<"Hello World"<<endl;
    //sch->Print();

    return 0;

}
