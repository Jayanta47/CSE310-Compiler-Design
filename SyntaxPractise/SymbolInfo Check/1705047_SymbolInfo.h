#ifndef SYMBOL_INFO_H
#include<string>
#include<vector>

struct param {
    std::string param_type;
    std::string param_name;
};

struct functionInfo
{
    std::string returnType;
    int n_params;
    std::vector<param*> param_list;
};

class symbolInfo
{
    std::string Name;
    std::string Type;
    std::string var_type;
    std::string id_type;
    int arrSize = 0;
    
    symbolInfo *next;
    symbolInfo *prev;
public:
    functionInfo *funcPtr;
    int arrIndex = 0;
    symbolInfo();
    symbolInfo(std::string Name, std::string Type);
    symbolInfo(std::string Type);
    symbolInfo(std::string Name, std::string Type, symbolInfo *next, symbolInfo *prev);
    ~symbolInfo();

    std::string getName();
    void setName(std::string newName);
    std::string getType();
    void setType(std::string newType);
    std::string getIdType();
    void setIdType(std::string idType);
    std::string getVarType();
    void setVarType(std::string varType);
    void setArrSize(int size);
    int getArrSize() {return this->arrSize;}
    void setFunctionInfo(functionInfo *funcPtr) {this->funcPtr = funcPtr;}
    functionInfo *getFunctionInfo() {return this->funcPtr;}
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


symbolInfo::symbolInfo(std::string Type)
{
    this->Name = "";
    this->Type = Type;
    this->next = nullptr;
    this->prev = nullptr;
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

std::string symbolInfo::getIdType() 
{
    return this->id_type;
}

void symbolInfo::setIdType(std::string idType)
{
    this->id_type = id_type;
}

std::string symbolInfo::getVarType() 
{
    return this->var_type;
}

void symbolInfo::setVarType(std::string varType)
{
    this->var_type = varType;
}

void symbolInfo::setArrSize(int size)
{
    this->arrSize = size;
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
    std::string thisSymbol = "< "+ this->Name + " : " + this->Type + "> ";
    return thisSymbol;
}

symbolInfo::~symbolInfo()
{
    if (this->next != nullptr)
    {       
        this->next = nullptr;
    }
    if (this->prev != nullptr)
    {
        this->prev = nullptr;
    }
}

#endif // SYMBOL_INFO_H
