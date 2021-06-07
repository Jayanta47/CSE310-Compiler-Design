#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

struct param {
    std::string param_type;
    std::string param_name;
};

struct functionInfo
{
    std::string returnType;
    bool onlyDeclared;
    std::vector<param*> param_list;
};

class symbolInfo
{
    std::string Name;
    std::string Type;
    std::string var_type; // the type of variable (to be returned|currently in hold)
    std::string id_type;
    int arrSize = -1;
    functionInfo *funcPtr;
    symbolInfo *next;
    symbolInfo *prev;
public:
    int arrIndex = 0;
    symbolInfo()
    {
    	this->next = nullptr;
    	this->prev = nullptr;
    }
    symbolInfo(std::string Name, std::string Type)
    {
        this->Name = Name;
        this->Type = Type;
        this->next = nullptr;
        this->prev = nullptr;
    }
    symbolInfo(std::string Type)
    {
        this->Name = "";
        this->Type = Type;
        this->next = nullptr;
        this->prev = nullptr;
    }
    symbolInfo(std::string Name, std::string Type, symbolInfo *next, symbolInfo *prev)
    {
        this->Name = Name;
        this->Type = Type;
        this->next = next;
        this->prev = prev;
    }
    ~symbolInfo()
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

    std::string getName() {return this->Name;}
    void setName(std::string newName) { this->Name = newName; }
    std::string getType() { return this->Type; }
    void setType(std::string newType) { this->Type = newType; }
    std::string getIdType() { return this->id_type; }
    void setIdType(std::string idType) { this->id_type = idType; }
    std::string getVarType() { return this->var_type; }
    void setVarType(std::string varType) { this->var_type = varType;}
    void setArrSize(int size) {this->arrSize = size;}
    int getArrSize() {return this->arrSize;}
    void setFunctionInfo(functionInfo *funcPtr) {this->funcPtr = funcPtr;}
    functionInfo *getFunctionInfo() {return this->funcPtr;}
    bool hasFuncPtr() {return this->funcPtr != nullptr;}
    bool funcDeclNotDef() {return this->funcPtr->onlyDeclared;}
    int getParamSize()
    {
        return (this->funcPtr != nullptr)?this->funcPtr->param_list.size():0;
    }
    void addParam(std::string param_name, std::string param_type)
    {
        param *temp = new param;
        temp->param_name = param_name;
        temp->param_type = param_type;
        if(this->funcPtr!=nullptr){this->funcPtr->param_list.push_back(temp);}
    }
    param *getParamAt(int index) const {return this->funcPtr->param_list[index];}
    symbolInfo *getNext() {return this->next;}
    void setNext(symbolInfo *newNext) {this->next = newNext;}
    symbolInfo *getPrev() {return this->prev;}
    void setPrev(symbolInfo *newPrev) {this->prev = newPrev;}
    bool equalsName(std::string Name) {return this->Name == Name;}
    std::string _str() {
        std::string thisSymbol = "< "+ this->Name + " , " + this->Type + "> ";
        return thisSymbol;
    }

};




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

    void buildBucket()
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
    void collectID()
    {
        if (this->parentScope == nullptr)
        {
            return;
        }

        this->idString = this->parentScope->idString + "." +
                            patch::to_string(this->id);
    }
    int hashIndex(std::string Name)
    {
        int hash_index = 0;
        for (int i = 0; i < Name.size(); i++)
        {
            hash_index += Name[i];
        }

        return hash_index%this->n_buckets;
    }
public:
    ScopeTable()
    {
        this->id = 0;
        this->n_buckets = 0;
        this->scopes_ctr = 0;
        this->parentScope = nullptr;
        this->bucket = nullptr;
        this->idString = "1";
    }
    ScopeTable(int n_buckets, int id)
    {
        this->n_buckets = n_buckets;
        this->id = id;
        this->scopes_ctr = 0;
        this->buildBucket();
        this->parentScope = nullptr;
        this->idString = patch::to_string(id);
    }
    ScopeTable(int n_buckets, int id, ScopeTable *parentScope)
    {
        this->n_buckets = n_buckets;
        this->id = id;
        this->scopes_ctr = 0;
        this->buildBucket();
        this->setParentScope(parentScope);
        this->collectID();
    }
    void setParentScope(ScopeTable *parentScope) {this->parentScope = parentScope;}
    ScopeTable *getParentScope() { return this->parentScope; }
    int getNextScopeNum()
    {
        scopes_ctr++;
        return scopes_ctr;
    }

    bool Insert(std::string Name, std::string Type)
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
    bool Insert(symbolInfo *item)
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
    symbolInfo *LookUp(std::string Name)
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
    bool Delete(std::string Name)
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
    void Print(FILE *file)
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

    ~ScopeTable()
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
};



class SymbolTable
{
private:
    int def_bucket_size;
    ScopeTable *currScopeTable;
    ScopeTable *tempPtr;

    FILE *fileWriter;
    bool writeToFile;

public:
    SymbolTable(int N)
    {
        this->def_bucket_size = N;
        this->tempPtr = nullptr;
        this->fileWriter = nullptr;
        this->currScopeTable = new ScopeTable(this->def_bucket_size, 1);
    }

    void EnterScope()
    {
        this->tempPtr = new ScopeTable(this->def_bucket_size,this->currScopeTable->getNextScopeNum(),
                                    this->currScopeTable);
        this->currScopeTable = this->tempPtr;
        this->tempPtr = nullptr;
    }
    void ExitScope()
    {
        if (this->currScopeTable->getParentScope() == nullptr)
        {
            return;
        }

        this->tempPtr = this->currScopeTable;
        this->currScopeTable = this->currScopeTable->getParentScope();
        delete this->tempPtr;
    }
    bool Insert(std::string Name, std::string Type)
    {
        bool accept = this->currScopeTable->Insert(Name, Type);
        if (!accept) {
            std::string msg = Name + " already exists in current ScopeTable";
            this->writeInFile(msg);
        }

        return accept;
    }
    bool Insert(symbolInfo *item) {return this->currScopeTable->Insert(item); /* NOTICE Check here */}
    bool Remove(std::string Name) { return this->currScopeTable->Delete(Name);}
    symbolInfo *LookUpInCurrent(std::string Name)
    {
        this->tempPtr = this->currScopeTable;
        symbolInfo *temp;
        temp = this->tempPtr->LookUp(Name);
        return temp;
    }
    symbolInfo *LookUpInAll(std::string Name)
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
    void printCurrentScopeTable() {this->currScopeTable->Print(this->fileWriter);}
    void printAllScopeTable()
    {
        this->tempPtr = this->currScopeTable;
        try
        {
            while(this->tempPtr != nullptr)
            {
                this->tempPtr->Print(this->fileWriter);
                this->tempPtr = this->tempPtr->getParentScope();
            }
        }
        catch(const std::exception& e)
        {
            std::cerr << e.what() << '\n';
        }

    }

    void setFileWriter(FILE *file)
    {
        this->writeToFile = true;
        this->fileWriter = file;
    }
    void writeInFile(std::string Msg) { if (this->writeToFile)fprintf(this->fileWriter, "%s\n\n", Msg.c_str()); }

    ~SymbolTable()
    {
        this->tempPtr = nullptr;
        this->currScopeTable = nullptr;
        this->fileWriter = nullptr;
    }
};


#endif
