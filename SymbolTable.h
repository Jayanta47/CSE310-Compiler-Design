#ifndef SYMBOL_TABLE_H

#include "ScopeTable.h"

class SymbolTable
{
private:
    int def_bucket_size;
    ScopeTable *currScopeTable;
    ScopeTable *tempPtr;

public:
    SymbolTable(int N);

    void EnterScope();
    void ExitScope();
    bool Insert(std::string Name, std::string Type);
    bool Insert(symbolInfo *item);
    bool Delete(std::string Name);
    symbolInfo *LookUp(std::string Name);
    void printCurrentScopeTable();
    void printAllScopeTable();

    ~SymbolTable();
};

SymbolTable::SymbolTable(int N)
{
    this->def_bucket_size = N;
    this->currScopeTable = new ScopeTable(this->def_bucket_size, 1);
    this->tempPtr = nullptr;
}

void SymbolTable::EnterScope()
{
    this->tempPtr = new ScopeTable(this->def_bucket_size,this->currScopeTable->getNextScopeNum(),
                                    this->currScopeTable);
    this->currScopeTable = this->tempPtr;
    this->tempPtr = nullptr;
}

void SymbolTable::ExitScope()
{
    if (this->currScopeTable->getParentScope() == nullptr)
    {
        std::cout<<"Cannot Exit Global Scope Table\n";
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

bool SymbolTable::Delete(std::string Name)
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
    //std::cout<<"Not Found\n";
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
        std::cout<<std::endl;
        this->tempPtr = this->tempPtr->getParentScope();
    }

}

SymbolTable::~SymbolTable()
{
    std::cout<<"Destroying Symbol Table\n";
    this->tempPtr = nullptr;
    this->currScopeTable = nullptr;
}

#endif