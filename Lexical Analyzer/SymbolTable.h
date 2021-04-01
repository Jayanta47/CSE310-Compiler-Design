#ifndef SYMBOL_TABLE_H

#include "ScopeTable.h"
#include <fstream>
class SymbolTable
{
private:
    int def_bucket_size;
    ScopeTable *currScopeTable;
    ScopeTable *tempPtr;

    FILE *fileWriter;
    bool writeToFile;

public:
    SymbolTable(int N);

    void EnterScope();
    void ExitScope();
    bool Insert(std::string Name, std::string Type);
    bool Remove(std::string Name);
    symbolInfo *LookUp(std::string Name);
    void printCurrentScopeTable();
    void printAllScopeTable();

    void setFileWriter(FILE *file);
    void writeInFile(std::string Msg);

    ~SymbolTable();
};

SymbolTable::SymbolTable(int N)
{
    this->def_bucket_size = N;
    this->tempPtr = nullptr;
    this->fileWriter = nullptr;
    this->currScopeTable = new ScopeTable(this->def_bucket_size, 1);
}


void SymbolTable::setFileWriter(FILE *file)
{
    this->writeToFile = true;
    this->fileWriter = file;
}

void SymbolTable::writeInFile(std::string Msg)
{
    if (this->writeToFile)fprintf(this->fileWriter, "%s\n\n", Msg.c_str());
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
        return;
    }

    this->tempPtr = this->currScopeTable;
    this->currScopeTable = this->currScopeTable->getParentScope();
    delete this->tempPtr;
}

bool SymbolTable::Insert(std::string Name, std::string Type)
{
    bool accept = this->currScopeTable->Insert(Name, Type);
    if (!accept) {
        // printf("\nfound %s\n", Name.c_str());
        std::string msg = Name + " already exists in current ScopeTable";
        this->writeInFile(msg);
    }

    return accept;
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
    this->currScopeTable->Print(this->fileWriter);
}

void SymbolTable::printAllScopeTable()
{
    this->tempPtr = this->currScopeTable;
    while(this->tempPtr != nullptr)
    {
        this->tempPtr->Print(this->fileWriter);
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