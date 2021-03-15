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
    ofstream *outfile = new ofstream(outputFileName);
    string Command; int value; string line;

    if (infile.is_open())
    {
        std::getline(infile, line);
        int n_bucket = stringToIntConverter(line);
        SymbolTable * ST = new SymbolTable(n_bucket, outfile);
        while (std::getline(infile, line))
        {
            (*outfile)<<line<<"\n\n";
            std::cout<<line<<"\n\n";
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
                    cout<<split_v[1] + " Not Found " + "\n\n";
                    (*outfile)<<split_v[1] + " Not Found " + "\n\n";
                }
            }
            else if (Command == "D")
            {
                if(!ST->Remove(split_v[1]))
                {
                    cout<<split_v[1] + " Not Found " + "\n\n";
                    (*outfile)<<split_v[1] + " Not Found " + "\n\n";
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
    cout<<"\n-------------------------------------------------------------"<<endl;
    if (writeToFile)
    {
        cout<<"Output written to File Successfully."<<endl;
    }
    outfile->close();
}

int main()
{
    IOparser("input0.txt", "output_0.txt");
    IOparser("input1.txt", "output_1.txt");
    IOparser("input2.txt", "output_2.txt");
    IOparser("input3.txt", "output_3.txt");
    IOparser("input4.txt", "output_4.txt");
    IOparser("input5.txt", "output_5.txt");


    return 0;

}
