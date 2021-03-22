#ifndef SYMBOL_INFO_H
#include<string>

class symbolInfo
{
    std::string Name;
    std::string Type;
    symbolInfo *next;
    symbolInfo *prev;
public:
    symbolInfo();
    symbolInfo(std::string Name, std::string Type);
    symbolInfo(std::string Name, std::string Type, symbolInfo *next, symbolInfo *prev);
    ~symbolInfo();

    std::string getName();
    void setName(std::string newName);
    std::string getType();
    void setType(std::string newType);
    symbolInfo *getNext();
    void setNext(symbolInfo *newNext);
    symbolInfo *getPrev();
    void setPrev(symbolInfo *newPrev);
    bool equalsName(std::string Name);
    std::string _str();

};


symbolInfo::symbolInfo()
{
    this->next = nullptr;
    this->prev = nullptr;
}

symbolInfo::symbolInfo(std::string Name, std::string Type)
{
    this->Name = Name;
    this->Type = Type;
    this->next = nullptr;
    this->prev = nullptr;
}

symbolInfo::symbolInfo(std::string Name, std::string Type, symbolInfo *next, symbolInfo *prev)
{
    this->Name = Name;
    this->Type = Type;
    this->next = next;
    this->prev = prev;
}

std::string symbolInfo::getName()
{
    return this->Name;
}

void symbolInfo::setName(std::string newName)
{
    this->Name = newName;
}

std::string symbolInfo::getType()
{
    return this->Type;
}

void symbolInfo::setType(std::string newType)
{
    this->Type = newType;
}

symbolInfo *symbolInfo::getNext()
{
    return this->next;
}

void symbolInfo::setNext(symbolInfo *newNext)
{
    this->next = newNext;
}

symbolInfo *symbolInfo::getPrev()
{
    return this->prev;
}

void symbolInfo::setPrev(symbolInfo *newPrev)
{
    this->prev = newPrev;
}

bool symbolInfo::equalsName(std::string Name)
{
    return this->Name == Name;
}

std::string symbolInfo::_str()
{
    std::string thisSymbol = " < "+ this->Name + " : " + this->Type + " > ";
    return thisSymbol;
}

symbolInfo::~symbolInfo()
{
    if (this->next != nullptr)
    {
        //std::cout<<"desc deleting="<<this->Name<<std::endl;
        this->next = nullptr;
    }
    if (this->prev != nullptr)
    {
        this->prev = nullptr;
    }
}

#endif // SYMBOL_INFO_H
