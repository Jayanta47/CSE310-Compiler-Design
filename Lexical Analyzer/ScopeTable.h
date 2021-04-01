#ifndef SCOPE_TABLE_H

#include "SymbolInfo.h"
#include <sstream>

namespace patch
{
    template < typename T > std::string to_string( const T& n )
    {
        std::ostringstream stm ;
        stm << n ;
        return stm.str() ;
    }
}

class ScopeTable
{
private:
    int n_buckets, id, scopes_ctr, index, pos;
    std::string idString;
    symbolInfo **bucket;
    ScopeTable *parentScope;

    std::ofstream *fileWriter;
    bool writeToFile = false;

    void buildBucket();
    void collectID();
    int hashIndex(std::string Name);
    // int getID() {return this->id;}
public:
    ScopeTable();
    ScopeTable(int n_buckets, int id, std::ofstream *ptr = nullptr);
    ScopeTable(int n_buckets, int id, ScopeTable *parentScope, std::ofstream *ptr = nullptr);

    void writeInFile(std::string Msg, bool lineGap = true);

    void setParentScope(ScopeTable *parentScope);
    ScopeTable *getParentScope();
    int getNextScopeNum();

    bool Insert(symbolInfo *item);
    bool Insert(std::string Name, std::string Type);
    symbolInfo *LookUp(std::string Name, bool showLoc = false);
    bool Delete(std::string Name);
    void Print();

    ~ScopeTable();
};

ScopeTable::ScopeTable()
{
    this->id = 0;
    this->n_buckets = 0;
    this->scopes_ctr = 0;
    this->parentScope = nullptr;
    this->bucket = nullptr;
    this->idString = "1";
    this->fileWriter = nullptr;
    this->writeToFile = false;
}

ScopeTable::ScopeTable(int n_buckets, int id,  std::ofstream *ptr)
{
    this->n_buckets = n_buckets;
    this->id = id;
    this->scopes_ctr = 0;
    this->buildBucket();
    this->parentScope = nullptr;
    this->fileWriter = ptr;
    if (ptr != nullptr) this->writeToFile = true;
    this->idString = patch::to_string(id);
}

ScopeTable::ScopeTable(int n_buckets, int id, ScopeTable *parentScope, std::ofstream *ptr)
{
    this->n_buckets = n_buckets;
    this->id = id;
    this->scopes_ctr = 0;
    this->buildBucket();
    this->setParentScope(parentScope);
    this->collectID();

    if (ptr!= nullptr)
    {
        this->fileWriter = ptr;
        this->writeToFile = true;
    }
}


void ScopeTable::writeInFile(std::string Msg, bool lineGap)
{
    (*this->fileWriter)<<Msg<<"\n";
    if (lineGap) (*this->fileWriter)<<"\n";
}

void ScopeTable::buildBucket()
{
    if (this->n_buckets == 0)
    {
        return;
    }

    this->bucket = new symbolInfo*[this->n_buckets];
    for (int i = 0; i < this->n_buckets; i++)
    {
        this->bucket[i] = nullptr;
    }

}

void ScopeTable::setParentScope(ScopeTable *parentScope)
{
    this->parentScope = parentScope;
}

ScopeTable *ScopeTable::getParentScope()
{
    return this->parentScope;
}

void ScopeTable::collectID()
{
    if (this->parentScope == nullptr)
    {
        return;
    }

    this->idString = this->parentScope->idString + "." +
                         patch::to_string(this->id);

}

int ScopeTable::getNextScopeNum()
{
    scopes_ctr++;
    return scopes_ctr;
}

int ScopeTable::hashIndex(std::string Name)
{
    int hash_index = 0;
    for (int i = 0; i < Name.size(); i++)
    {
        hash_index += Name[i];
    }

    return hash_index%this->n_buckets;
}

bool ScopeTable::Insert(symbolInfo *item)
{
    symbolInfo *returnPtr = this->LookUp(item->getName(), false);
    if (returnPtr != nullptr)
    {
        std::string Msg = returnPtr->_str() + " already exists in current ScopeTable";
        if (writeToFile) this->writeInFile(Msg);
        return false;
    }

    int index = this->hashIndex(item->getName());
    int pos = 0;

    if (this->bucket[index] != nullptr)
    {
        symbolInfo *temp = this->bucket[index];
        while(temp->getNext() != nullptr)
        {
            temp = temp->getNext();
            pos++;
        }
        temp->setNext(item);
        item->setPrev(temp);
        pos++;
    }
    else
    {
        this->bucket[index] = item;
    }

    // std::string Msg = "Inserted in ScopeTable# " + this->idString + " at position " 
    //                     + patch::to_string(index) + ", " + patch::to_string(pos);
    // this->writeInFile(Msg);

    return true;
}

bool ScopeTable::Insert(std::string Name, std::string Type)
{
    symbolInfo *returnPtr = this->LookUp(Name, false);
    if (returnPtr != nullptr)
    {
        std::string Msg = returnPtr->_str() + " already exists in current ScopeTable";
        if (writeToFile) this->writeInFile(Msg);
        return false;
    }

    symbolInfo *item = new symbolInfo(Name, Type);
    int index = this->hashIndex(Name);
    int pos = 0;

    if (this->bucket[index] != nullptr)
    {
        symbolInfo *temp = this->bucket[index];
        while(temp->getNext() != nullptr)
        {
            temp = temp->getNext();
            pos++;
        }
        temp->setNext(item);
        item->setPrev(temp);
        pos++;
    }
    else
    {
        this->bucket[index] = item;
    }

    // std::string Msg = "Inserted in ScopeTable# " + this->idString + " at position " 
    //                     + patch::to_string(index) + ", " + patch::to_string(pos);
    // if (writeToFile) this->writeInFile(Msg);

    return true;

}

symbolInfo *ScopeTable::LookUp(std::string Name, bool showLoc)
{
    int index = this->hashIndex(Name);
    symbolInfo *symPtr = this->bucket[index];
    int pos = 0;

    while(symPtr != nullptr)
    {
        if (symPtr->equalsName(Name))
        {
            std::string Msg = "Found in ScopeTable# " + this->idString + " at position "
                                + patch::to_string(index) + ", " + patch::to_string(pos);
            this->index = index;
            this->pos = pos;
            if(showLoc)
            {
                if (writeToFile) this->writeInFile(Msg);
            }
            
            return symPtr;
        }
        pos++;
        symPtr = symPtr->getNext();

    }

    return nullptr;
}

bool ScopeTable::Delete(std::string Name)
{
    symbolInfo *delItem = this->LookUp(Name);

    if (delItem == nullptr)
    {
        //if (writeToFile) this->writeInFile("Not Found");
        return false;
    }
    if (delItem->getPrev() != nullptr)
    {
        delItem->getPrev()->setNext(delItem->getNext());
    }
    else
    {
        this->bucket[index] = delItem->getNext();
    }

    if (delItem->getNext() != nullptr)
    {
        delItem->getNext()->setPrev(delItem->getPrev());
    }

    delete delItem;

    // std::string Msg = "Deleted Entry " + patch::to_string(this->index) + ", " + 
    //                     patch::to_string(this->pos) + " from current ScopeTable";
    // if (writeToFile) this->writeInFile(Msg);
    return true;
}

void ScopeTable::Print()
{
    if (this->writeToFile) this->writeInFile("\nScopeTable # " + this->idString, false);
    for (int i = 0; i < this->n_buckets; i++)
    {
        if (this->writeToFile) (*this->fileWriter)<<i<<" --> ";
        if (this->bucket[i] != nullptr)
        {
            symbolInfo *temp = this->bucket[i];
            while(temp != nullptr)
            {
                if (this->writeToFile) (*this->fileWriter)<<temp->_str()<<" ";
                temp = temp->getNext();
            }
        }
        (*this->fileWriter)<<"\n";

    }
    (*this->fileWriter)<<"\n";
}

ScopeTable::~ScopeTable()
{
    for (int i = 0; i< this->n_buckets; i++)
    {
        if (this->bucket[i] != nullptr)
        {
            symbolInfo *current;
            current = this->bucket[i];
            while(current != nullptr)
            {
                symbolInfo *del = current;
                current = current->getNext();
                delete del;
            }
        }
    }

    this->fileWriter = nullptr;

    // std::string Msg = "ScopeTable with id " + this->idString + " removed";
    // std::cout<<Msg<<"\n\n";
    // this->writeInFile(Msg);
}


#endif
