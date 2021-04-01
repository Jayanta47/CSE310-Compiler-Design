#ifndef SYMBOL_TABLE_H

#include "ScopeTable.h"
#include <fstream>
class SymbolTable
{
private:
    int def_bucket_size;
    ScopeTable *currScopeTable;
    ScopeTable *tempPtr;

    std::ofstream *fileWriter;
    bool writeToFile;

public:
    SymbolTable(int N, std::ofstream *ptr = nullptr);
    SymbolTable(int N, std::string filename);

    void EnterScope();
    void ExitScope();
    bool Insert(std::string Name, std::string Type);
    bool Insert(symbolInfo *item);
    bool Remove(std::string Name);
    symbolInfo *LookUp(std::string Name);
    void printCurrentScopeTable();
    void printAllScopeTable();

    void setFileWriter(std::ofstream *ptr);
    void writeInFile(std::string Msg);

    ~SymbolTable();
};

SymbolTable::SymbolTable(int N, std::ofstream *ptr)
{
    this->def_bucket_size = N;
    this->tempPtr = nullptr;
    this->fileWriter = ptr;
    if (ptr != nullptr) this->writeToFile = true;
    this->currScopeTable = new ScopeTable(this->def_bucket_size, 1, this->fileWriter);
}

SymbolTable::SymbolTable(int N, std::string filename = "output.txt")
{
    this->def_bucket_size = N;
    this->tempPtr = nullptr;
    this->writeToFile = true;
    this->fileWriter = new std::ofstream(filename); 
    this->currScopeTable = new ScopeTable(this->def_bucket_size, 1, this->fileWriter);
}

void SymbolTable::setFileWriter(std::ofstream *ptr)
{
    this->writeToFile = true;
    this->fileWriter = ptr;
}

void SymbolTable::writeInFile(std::string Msg)
{
    (*this->fileWriter)<<Msg<<"\n\n";
}

void SymbolTable::EnterScope()
{
    this->tempPtr = new ScopeTable(this->def_bucket_size,this->currScopeTable->getNextScopeNum(),
                                    this->currScopeTable, this->fileWriter);
    this->currScopeTable = this->tempPtr;
    this->tempPtr = nullptr;
}

void SymbolTable::ExitScope()
{
    if (this->currScopeTable->getParentScope() == nullptr)
    {
        // if (this->writeToFile)
        // {
        //     this->writeInFile("Cannot Exit Global Scope Table");
        // }
        return;
    }

    this->tempPtr = this->currScopeTable;
    this->currScopeTable = this->currScopeTable->getParentScope();
    delete this->tempPtr;
}

bool SymbolTable::Insert(std::string Name, std::string Type)
{
    return this->currScopeTable->Insert(Name, Type);
}

bool SymbolTable::Insert(symbolInfo *item)
{
    return this->currScopeTable->Insert(item);
}

bool SymbolTable::Remove(std::string Name)
{
    return this->currScopeTable->Delete(Name);
}

symbolInfo *SymbolTable::LookUp(std::string Name)
{
    this->tempPtr = this->currScopeTable;
    symbolInfo *temp;
    while(this->tempPtr != nullptr)
    {
        temp = this->tempPtr->LookUp(Name);
        if (temp != nullptr)
        {
            return temp;
        }
        else
        {
            this->tempPtr = this->tempPtr->getParentScope();
        }
    }

    return nullptr;
}

void SymbolTable::printCurrentScopeTable()
{
    this->currScopeTable->Print();
}

void SymbolTable::printAllScopeTable()
{
    this->tempPtr = this->currScopeTable;
    while(this->tempPtr != nullptr)
    {
        this->tempPtr->Print();
        this->tempPtr = this->tempPtr->getParentScope();
    }

}

SymbolTable::~SymbolTable()
{
    this->tempPtr = nullptr;
    this->currScopeTable = nullptr;
    this->fileWriter = nullptr;
}

#endif