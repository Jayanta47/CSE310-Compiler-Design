#include<iostream>
#include<string>
#include<fstream>
#include<iterator>
#include<vector>
using namespace std;
#include "SymbolTable.h"

using namespace std;

void split(const string& str, vector<string>& cont)
{
    istringstream iss(str);
    copy(istream_iterator<string>(iss),
         istream_iterator<string>(),
         std::back_inserter(cont));
}

int stringToIntConverter(string s)
{
    stringstream stoiC(s);
    int retValue;
    stoiC>>retValue;
    return retValue;
}

void IOparser(string inputFileName, string outputFileName="output.txt")
{
    bool writeToFile = true;

    cout<<"Reading From File : '"<<inputFileName<<"'"<<endl;
    cout<<"Parsing Commands ... "<<endl;

    cout<<"Writing outputs into File - Filename : '"<<outputFileName<<"'"<<endl;


    cout<<"\n-------------------------------------------------------------"<<endl;
    cout<<"Output Log:"<<endl;
    cout<<"-------------------------------------------------------------"<<endl<<endl;
    

    ifstream infile(inputFileName);
    ofstream outfile(outputFileName);
    string Command; int value; string line;

    if (infile.is_open())
    {
        std::getline(infile, line);
        int n_bucket = stringToIntConverter(line);
        SymbolTable * ST = new SymbolTable(n_bucket);
        while (std::getline(infile, line))
        {
            vector<string> split_v;
            split(line, split_v);
            Command = split_v[0];
            if (Command == "I")
            {
                ST->Insert(split_v[1], split_v[2]);
            }
            else if (Command == "L")
            {
                if(ST->LookUp(split_v[1]) == nullptr)
                {
                    cout<<"Not Found\n\n";
                }
            }
            else if (Command == "D")
            {
                if(ST->Delete(split_v[1]))
                {
                    cout<<"Not Found\n\n";
                }
            }
            else if (Command == "P")
            {
                if (split_v[1] == "A")
                {
                    ST->printAllScopeTable();
                }
                else if (split_v[1] == "C")
                {
                    ST->printCurrentScopeTable();
                }
                else 
                {
                    cout<<"Invalid Command"<<endl;
                }
            }
            else if (Command == "S")
            {
                ST->EnterScope();
            }
            else if (Command == "E")
            {
                ST->ExitScope();
            }
            else
            {
                cout<<"Invalid Argument Read From File.\nReturning..."<<endl;
                return;
            }
        }

    }
    infile.close();
    if (writeToFile)
    {
        cout<<"Output written to File Successfully."<<endl;
    }
    cout<<"\n-------------------------------------------------------------"<<endl;
    outfile.close();
}

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
    // A = B;

    // cout<<A->getName()<<" "<<A->getType()<<" \n";


    // string a = "abcd";
    // for (int i=0;i<a.size(); i++)
    // {
    //     int b = a[i];
    //     cout<<b<<endl;
    // }
    // ScopeTable *sch = new ScopeTable(6, 1);
    // sch->Print();
    // bool state = sch->Insert("ab", "Integer");
    // sch->Insert("b", "Integer");
    // sch->Insert("c", "Integer");
    // sch->Insert("lkk", "Integer");
    // sch->Insert("erd", "Integer");
    // sch->Delete("c");
    // sch->LookUp("b");

    // sch->Print();

    // ScopeTable *sch2 = new ScopeTable(6, 1, sch);
    // sch2->Insert("ab", "String");

    // cout<<"Compiler Sessional : Symbol Table"<<endl;



    

    // sch2->Print();

    // delete sch2;

    // sch->Print();

    IOparser("input.txt");

    return 0;

}
