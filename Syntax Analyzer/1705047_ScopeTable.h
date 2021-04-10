#ifndef SCOPE_TABLE_H

#include "1705047_SymbolInfo.h"
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

    void buildBucket();
    void collectID();
    int hashIndex(std::string Name);
public:
    ScopeTable();
    ScopeTable(int n_buckets, int id);
    ScopeTable(int n_buckets, int id, ScopeTable *parentScope);

    void setParentScope(ScopeTable *parentScope);
    ScopeTable *getParentScope();
    int getNextScopeNum();

    bool Insert(std::string Name, std::string Type);
    bool Insert(symbolInfo *item);
    symbolInfo *LookUp(std::string Name);
    bool Delete(std::string Name);
    void Print(FILE *file);

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
}

ScopeTable::ScopeTable(int n_buckets, int id)
{
    this->n_buckets = n_buckets;
    this->id = id;
    this->scopes_ctr = 0;
    this->buildBucket();
    this->parentScope = nullptr;
    this->idString = patch::to_string(id);
}

ScopeTable::ScopeTable(int n_buckets, int id, ScopeTable *parentScope)
{
    this->n_buckets = n_buckets;
    this->id = id;
    this->scopes_ctr = 0;
    this->buildBucket();
    this->setParentScope(parentScope);
    this->collectID();
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
    symbolInfo *returnPtr = this->LookUp(item->getName());
    if (returnPtr != nullptr)
    {
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

    return true;
}

bool ScopeTable::Insert(std::string Name, std::string Type)
{
    symbolInfo *returnPtr = this->LookUp(Name);
    if (returnPtr != nullptr)
    {
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

    return true;

}

symbolInfo *ScopeTable::LookUp(std::string Name)
{
    int index = this->hashIndex(Name);
    symbolInfo *symPtr = this->bucket[index];
    int pos = 0;

    while(symPtr != nullptr)
    {
        if (symPtr->equalsName(Name))
        {
            this->index = index;
            this->pos = pos;
            
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
    return true;
}

void ScopeTable::Print(FILE *file)
{
    std::string msg = "ScopeTable # " + this->idString;
    fprintf(file, "%s\n", msg.c_str());
    for (int i = 0; i < this->n_buckets; i++)
    {
        
        if (this->bucket[i] != nullptr)
        {
            fprintf(file, " %d --> ", i);
            symbolInfo *temp = this->bucket[i];
            while(temp != nullptr)
            {
                fprintf(file, "%s", temp->_str().c_str());
                temp = temp->getNext();
            }
            fprintf(file, "\n");
        }
        

    }
    fprintf(file, "\n");
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

}


#endif
