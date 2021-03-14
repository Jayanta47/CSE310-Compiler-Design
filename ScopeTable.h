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

    void buildBucket();
    void collectID();
    int hashIndex(std::string Name);
    // int getID() {return this->id;}
public:
    ScopeTable();
    ScopeTable(int n_buckets, int id);
    ScopeTable(int n_buckets, int id, ScopeTable *parentScope);

    void creationMsg();
    void setParentScope(ScopeTable *parentScope);
    ScopeTable *getParentScope();
    int getNextScopeNum();

    bool Insert(symbolInfo *item);
    bool Insert(std::string Name, std::string Type);
    symbolInfo *LookUp(std::string Name, bool showLoc = true);
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
    this->creationMsg();
}

void ScopeTable::creationMsg()
{
    std::cout<<"New ScopeTable with id "<<this->idString<<" created\n";
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
    // cout<<"Allocation done"<<endl;

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

    ScopeTable *scopeTablePtr = this->parentScope;
    std::string idTemp = patch::to_string(this->id);
    while(scopeTablePtr != nullptr)
    {
        idTemp = patch::to_string(scopeTablePtr->id) + "." + idTemp;
        scopeTablePtr = scopeTablePtr->parentScope;
    }

    this->idString = idTemp;

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
    // std::cout<<"Hello start\n";
    if (this->LookUp(item->getName(), false) != nullptr)
    {
        std::cout<<"<"<<item->getName()<<", "<<item->getType()<<"> already exists in current ScopeTable"<<std::endl;
        return false;
    }

    int index = this->hashIndex(item->getName());
    int pos = 0;

    // symbolInfo *temp = this->bucket[index];
    // if (temp != nullptr)
    // {
    //     while(temp != nullptr)
    //     {
    //         temp = temp->getNext();
    //         pos++;
    //     }
    //     temp->setNext(item);
    //     item->setPrev(temp);
    // }
    // else
    // {
    //     this->bucket[index] = item;
    // }

    if (this->bucket[index] != nullptr)
    {
        symbolInfo *temp = this->bucket[index];
        while(temp->getNext() != nullptr)
        {
            temp = temp->getNext();
            pos++;
            std::cout<<"Hello\n";
        }
        temp->setNext(item);
        item->setPrev(temp);

    }
    else
    {
        this->bucket[index] = item;
    }

    std::cout<<"Inserted in ScopeTable# "<<this->idString
        <<" at position "<<index<<" ,"<<pos<<std::endl;

    return true;
}

bool ScopeTable::Insert(std::string Name, std::string Type)
{
    if (this->LookUp(Name, false) != nullptr)
    {
        std::cout<<"<"<<Name<<", "<<Type<<"> already exists in current ScopeTable"<<std::endl;
        return false;
    }

    symbolInfo *item = new symbolInfo(Name, Type);
    int index = this->hashIndex(Name);
    int pos = 0;

    // symbolInfo *temp = this->bucket[index];
    // if (temp != nullptr)
    // {
    //     while(temp != nullptr)
    //     {
    //         temp = temp->getNext();
    //         pos++;
    //     }
    //     temp->setNext(item);
    //     item->setPrev(temp);
    // }
    // else
    // {
    //     this->bucket[index] = item;
    // }

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

    }
    else
    {
        this->bucket[index] = item;
    }

    std::cout<<"Inserted in ScopeTable# "<<this->idString
        <<" at position "<<index<<" ,"<<pos+1<<std::endl;

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
            if(showLoc)
            {
                std::cout<<"Found in ScopeTable# "<<this->idString
                <<" at position "<<index<<", "<<pos<<std::endl;
                this->index = index;
                this->pos = pos;
            }
            return symPtr;
        }
        pos++;
        symPtr = symPtr->getNext();

    }

    //if (showLoc) std::cout<<"Not found"<<std::endl; // handle this outside the class
    return nullptr;
}

bool ScopeTable::Delete(std::string Name)
{
    symbolInfo *delItem = this->LookUp(Name);

    if (delItem == nullptr)
    {
        std::cout<<"Not Found"<<std::endl;
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
    std::cout<<"Deleted Entry "<<this->index<<", "<<this->pos
                <<" from current ScopeTable"<<std::endl;
    return true;
}

void ScopeTable::Print()
{
    std::cout<<"ScopeTable # "<<this->idString<<"\n";
    for (int i = 0; i < this->n_buckets; i++)
    {
        std::cout<<i<<" --> ";
        if (this->bucket[i] != nullptr)
        {
            symbolInfo *temp = this->bucket[i];
            while(temp != nullptr)
            {
                std::cout<<temp->_str()<<" ";
                //std::cout<<" ha";
                temp = temp->getNext();
            }
        }
        std::cout<<"\n";

    }
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

    std::cout<<"Succesfully Deleted Scope Table\n";
}


#endif
