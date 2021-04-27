%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<regex>
#include "SymbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);

int ERR_COUNT=0;
int SMNTC_ERR_COUNT = 0;
extern int lineCnt;

extern FILE *yyin;
FILE *fp;
FILE *logFile;
FILE *errorFile;


// containers and structures

struct variableInfo {
	std::string var_name;
	std::string var_size;
};

std::string code_segm;
vector<string> code_vect;
vector<symbolInfo*> arg_vect;
vector<variableInfo*> var_vect;
vector<param*> temp_param_list;
SymbolTable *table;

// auxilliary variables
variableInfo *varPtr;
param *p;
std::string type, final_type;
std::string name, final_name;
std::string return_type;

// defined functions
void insertVarIntoTable(std::string varType, variableInfo *vp)
{
	symbolInfo *si = new symbolInfo(vp->var_name, "ID");
	si->setVarType(varType);
	int varSize = atoi(vp->var_size.c_str());
	//printf("Insertion func, array size = %d\n", varSize);
	si->setArrSize(varSize);
	if (varSize == -1) {si->setIdType("variable");}
	else 
	{
		si->setIdType("array");
		//printf("declaring array for %s, size=%d, id = %s\n", si->getName().c_str(), si->getArrSize(), si->getIdType().c_str());

	}
	table->Insert(si);
}

void insertFuncIntoTable(std::string name, functionInfo* funcPtr)
{
	symbolInfo *si = new symbolInfo(name, "ID");
	si->setIdType("function");
	
	si->setVarType(funcPtr->returnType);
	//printf("insert func %s with var type %s\n",si->getName().c_str(), si->getVarType().c_str());
	si->setFunctionInfo(funcPtr);
	if(table->Insert(si))
	{
		//printf("insert func %s with var type %s\n",si->getName().c_str(), si->getVarType().c_str());
	}
}

void checkFunctionDef(std::string funcName, std::string returnType)
{
	symbolInfo *x = table->LookUpInAll(funcName);
	if (x == nullptr)
	{
		functionInfo *f = new functionInfo;
		f->returnType = returnType;
		f->onlyDefined = false;
		std::vector<param*> param_list;
		// There can be multiple declarations of a parameter inside param_list
		// Multiple declarations of same param raises error
		for (int i=0;i<temp_param_list.size();i++)
		{
			for (int j=0; j<param_list.size();j++)
			{
				if(param_list[j]->param_name == temp_param_list[i]->param_name &&
					param_list[j]->param_type == temp_param_list[i]->param_type)
				{
					fprintf(logFile, "Error at line %d : Multiple declaration of %s in parameter\n\n", lineCnt, param_list[j]->param_name.c_str());
					fprintf(errorFile, "Line no %d : Multiple declaration of %s in parameter\n\n", lineCnt, param_list[j]->param_name.c_str());
					SMNTC_ERR_COUNT++;
				}
				else if (param_list[j]->param_name == temp_param_list[i]->param_name)
				{
					fprintf(logFile, "Error at line %d : Multiple declaration of %s (as type %s and %s) in parameter\n\n", 
							lineCnt, param_list[j]->param_name.c_str());
					fprintf(errorFile, "Line no %d : Multiple declaration of %s (as type %s and %s) in parameter\n\n", 
							lineCnt, param_list[j]->param_name.c_str());
					SMNTC_ERR_COUNT++;
				}
			}
			param_list.push_back(temp_param_list[i]);
		}
		f->param_list = param_list;
		//printf("inserting func name %s into table at line %d\n", funcName.c_str(), lineCnt);
		insertFuncIntoTable(funcName, f);
	}
	else if (x->getIdType()!="function")
	{
		fprintf(errorFile, "Line no %d : Multiple declaration of %s\n\n", lineCnt, funcName.c_str());
		SMNTC_ERR_COUNT++;
	}
	else if (!x->hasFuncPtr())
	{
		fprintf(logFile, "Line no %d : function previously defined but not properly structured\n\n", lineCnt);
		SMNTC_ERR_COUNT++;
	}
	else if (!x->funcDeclNotDef())
	{
		fprintf(logFile, "Line no %d : Multiple definitions of same function (name:%s)\n\n", lineCnt, funcName);
		SMNTC_ERR_COUNT++;
	}
	else 
	{
		//function declaration found
		//need to match parameter types		

		// check return type
		//printf("passed return type = %s\n", returnType.c_str());
		//printf("checking return type for %s with return type = %s\n", x->getName().c_str(), x->getVarType().c_str());
		if (returnType != x->getVarType())
		{
			fprintf(errorFile, "Line no %d : Return type mismatch with function declaration in function %s\n\n", lineCnt, x->getName().c_str());
			fprintf(logFile, "Error at line %d : Return type mismatch with function declaration in function %s\n\n", lineCnt, x->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		else if (x->getParamSize() == 1 && temp_param_list.size()==0 && x->getParamAt(0)->param_type == "void")
		{
			// didnt understand this
			x->getFunctionInfo()->onlyDefined = false;
		}
		else if (x->getParamSize() == 0 && temp_param_list.size()==1 && temp_param_list[0]->param_type == "void")
		{
			// didnt understand this
			x->getFunctionInfo()->onlyDefined = false;
		}
		else 
		{
			// check parameter consistency
			//printf("for function %s, def_size = %d\n", x->getName().c_str(), x->getParamSize());

			if (x->getParamSize() != temp_param_list.size())
			{
				fprintf(errorFile, "Line no %d : Total number of arguments mismatch with declaration in function %s\n\n", lineCnt, x->getName().c_str());
				fprintf(logFile, "Error at line %d : Total number of arguments mismatch with declaration in function %s\n\n", lineCnt, x->getName().c_str());
				SMNTC_ERR_COUNT++;
			}
			else 
			{
				int i;
				for (i=0; i<temp_param_list.size(); i++)
				{
					if (temp_param_list[i]->param_type != x->getParamAt(i)->param_type)
					{
						fprintf(logFile, "Line no %d : Parameter Type mismatch\n\n", lineCnt);
						SMNTC_ERR_COUNT++;
						break;
					}
				}
				if (i == temp_param_list.size())
				{
					x->getFunctionInfo()->onlyDefined = false;
				}
			}
		}
	}

	//temp_param_list.clear();
}

void checkFunctionDec(std::string funcName, std::string returnType)
{
	symbolInfo *x = table->LookUpInAll(funcName);
	if (x == nullptr)
	{
		functionInfo *f = new functionInfo;
		f->returnType = returnType;
		f->onlyDefined = true;
		f->param_list = temp_param_list;
		insertFuncIntoTable(funcName, f);
	}
	else 
	{
		fprintf(logFile, "Line no %d : Multiple definitions for function %s\n\n", lineCnt, funcName.c_str());
		fprintf(errorFile, "Line no %d : Multiple definitions for function %s\n\n", lineCnt, funcName.c_str());
		SMNTC_ERR_COUNT++;
	}
}

bool isNameOfArr(std::string Name)
{
	std::regex b("[a-zA-Z_][a-zA-Z0-9_]*\[[0-9]+\]");
	return std::regex_match(Name, b);
}

std::string stripArr(std::string Name)
{
	int i;
	for(i=0; i<Name.size(); i++)
	{
		if(Name[i]=='[')break;
	}
	if (i>=Name.size())
	{
		printf("error in array name sent to strip array function\n");
		return Name;
	}
	else
	{
		//printf("strip = %s\n", Name.substr(0, i).c_str());
		return Name.substr(0, i);
	}

}

void yyerror(char *s)
{
	//write your code
	ERR_COUNT++;
	fprintf(logFile, "Error at Line %d: %s\n\n", lineCnt, s);
	fprintf(errorFile, "Error at Line %d: %s\n\n", lineCnt, s);
}


%}

%union {
	symbolInfo *symbol;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN 
%token SWITCH CASE DEFAULT CONTINUE ASSIGNOP LPAREN RPAREN LCURL RCURL 
%token LTHIRD RTHIRD COMMA SEMICOLON NOT PRINTLN INCOP DECOP PRINTF
%token<symbol>CONST_INT
%token<symbol>CONST_FLOAT
%token<symbol>ID
%token<symbol>ADDOP
%token<symbol>MULOP
%token<symbol>RELOP
%token<symbol>LOGICOP

%type<symbol>unit func_declaration func_definition func_definition_initP func_definition_init parameter_list  
%type<symbol>compound_statement var_declaration type_specifier declaration_list statements statement  
%type<symbol>expression_statement variable expression logic_expression rel_expression simple_expression term 
%type<symbol>unary_expression factor argument_list arguments

//%type<symbol>dumping_state dump_simple_expr dump_expr_statement
%type<symbol>error_statement error_expression
//%type<symbol>simple_expression_error // rel_expression_error //logic_expression_error


// %left 
// %right
%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE 


%%

start : program
	{
		fprintf(logFile, "At line no: %d start : program\n\n", lineCnt-1);// lineCnt is decreased by 1 
												//because it read the last newline of input file and falsely incremented line count
		for (auto str : code_vect)
		{
			fprintf(logFile, "%s\n", str.c_str());
		}
		fprintf(logFile, "\n");
	}
	;

program : program unit 
	{
		fprintf(logFile, "At line no: %d program : program unit\n\n", lineCnt);
		code_vect.push_back($2->getName());
		for(int i = 0; i < code_vect.size(); i++)
		{
			fprintf(logFile, "%s\n", code_vect[i].c_str());
		}
		fprintf(logFile, "\n");
	}
	| unit
	{
		fprintf(logFile, "At line no: %d program : unit\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		code_vect.push_back($1->getName());
	}
	;
	
unit : var_declaration
	{
		//printf("Var dec\n");
		//printf("%s\n\n", $1->getName().c_str());
		fprintf(logFile, "At line no: %d unit : var_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName(), "unit");
		$$ = si;
		//printf("var dec unit = %s\n", $1->getName().c_str());
		//printf("exit var\n");
	}
	| func_declaration
	{
		fprintf(logFile, "At line no: %d unit : func_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName(), "unit");
		$$ = si;
	}
	| func_definition
	{
		//printf("func def\n");
		fprintf(logFile, "At line no: %d unit : func_definition\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName(), "unit");
		$$ = si;
	}
	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lineCnt);
		code_segm = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ");" ;
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		$$ = new symbolInfo(code_segm, "func_declaration");
		checkFunctionDec($2->getName(), $1->getName());
		temp_param_list.clear();
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", lineCnt);
		code_segm = $1->getName() + " " + $2->getName() + "(" + ");" ;
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		$$ = new symbolInfo(code_segm, "func_declaration");
		checkFunctionDec($2->getName(), $1->getName());
	}
	;
		 
func_definition : func_definition_initP compound_statement
	{
		fprintf(logFile, "At line no %d : func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", lineCnt);
		code_segm = $1->getName() + $2->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "func_definition");
		si->setVarType($1->getVarType());
		$$=si;	
	}
	| func_definition_init compound_statement
	{
		fprintf(logFile, "At line no %d : func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n", lineCnt);
		code_segm = $1->getName() + $2->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "func_definition");
		si->setVarType($1->getVarType());
		$$=si;
	}
	;	

func_definition_initP : type_specifier ID LPAREN parameter_list RPAREN
	{
		checkFunctionDef($2->getName(), $1->getName());	
		code_segm = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ")";
		$$ = new symbolInfo(code_segm, "func_definition_initP");
		$$->setVarType($1->getName());
	};

func_definition_init : type_specifier ID LPAREN RPAREN 
	{
		checkFunctionDef($2->getName(), $1->getName());	
		code_segm = $1->getName() + " " + $2->getName() + "()";
		$$ = new symbolInfo(code_segm, "func_definition_init");
		$$->setVarType($1->getName());
	};

parameter_list  : parameter_list COMMA type_specifier ID
	{
		fprintf(logFile, "At line no %d : parameter_list : parameter_list COMMA type_specifier ID\n\n", lineCnt);
		code_segm = $1->getName() + "," + $3->getName() + " " + $4->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		$$=si;
		p = new param;
		p->param_type = $3->getName();
		p->param_name = $4->getName();
		temp_param_list.push_back(p);
	}
	| parameter_list COMMA type_specifier
	{
		fprintf(logFile, "At line no %d : parameter_list : parameter_list COMMA type_specifier\n\n", lineCnt);
		code_segm = $1->getName() + "," + $3->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		$$=si;
		p = new param;
		p->param_type = $3->getName();
		p->param_name = "";
		temp_param_list.push_back(p);
	}
	| type_specifier ID
	{
		fprintf(logFile, "At line no: %d parameter_list : type_specifier ID\n\n", lineCnt);
		code_segm = $1->getName() + " " + $2->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		$$ = si;
		p = new param;
		p->param_type = $1->getName();
		p->param_name = $2->getName();
		temp_param_list.push_back(p);
	}
	| type_specifier
	{
		fprintf(logFile, "At line no %d : parameter_list : type_specifier\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1; $$->setType("parameter_list");
		p = new param;
		p->param_type = $1->getName();
		p->param_name = "";
		temp_param_list.push_back(p);
	}
	| type_specifier error 
	{
		printf("error reporting\n");
		yyclearin;
		yyerrok;
	}
	;

 		
compound_statement : LCURL interimScopeAct statements RCURL
	{
		
		fprintf(logFile, "At line no: %d compound_statement : LCURL statements RCURL\n\n", lineCnt);
		code_segm = "{\n"+$3->getName()+"}";
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "compound_statement");
		$$=si;
		table->printAllScopeTable();
		
		table->ExitScope();

	}
	| LCURL interimScopeAct RCURL
	{
		fprintf(logFile, "At line no %d : compound_statement : LCURL RCURL\n\n", lineCnt);
		code_segm = "{\n}";
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "compound_statement");
		$$=si;
		table->printAllScopeTable();
		table->ExitScope();
	}
	;

interimScopeAct : 
	{
		table->EnterScope();
		//printf("Enterred new scope\n\n");
		if(temp_param_list.size()>1 || (temp_param_list.size() == 1 && temp_param_list[0]->param_type != "void"))
		{
			for(int i=0;i<temp_param_list.size();i++)
			{
				p = temp_param_list[i];
				varPtr = new variableInfo;
				varPtr->var_name = p->param_name;
				varPtr->var_size = "-1";
				insertVarIntoTable(p->param_type, varPtr);
			}
		}
		temp_param_list.clear();
	}
	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
	{
		//printf("Inside VAR dec\n");
		fprintf(logFile, "At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n\n", lineCnt);
		fprintf(logFile, "%s %s;\n\n", $1->getName().c_str(), $2->getName().c_str());
		code_segm = $1->getName()+" "+$2->getName()+";";
		//printf("var dec = %s\n", code_segm.c_str());
		symbolInfo *si =  new symbolInfo(code_segm, "var_declaration");
		//printf("symbolInfo = %s\n", si->getName().c_str());
		$$=si;
		//printf("var dec = %s\n", $$->getName().c_str());
		std::string varType = $1->getName();
		if ($1->getType() == "VOID") 
		{
			fprintf(errorFile, "Line no %d : Variable type cannot be void\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Variable type cannot be void\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			varType = "int"; // default var type int
		}
		for ( int i=0; i<var_vect.size(); i++) 
		{
			insertVarIntoTable(varType, var_vect[i]);
			//printf("insert into table, %s\n", var_vect[i]->var_name.c_str());
		} 
		var_vect.clear();
	}
	;
 		 
type_specifier : INT
	{
		
		fprintf(logFile, "At line no: %d type_specifier : INT\n\n", lineCnt);
		fprintf(logFile, "int\n\n"); 
		symbolInfo *type = new symbolInfo("int", "INT");
		$$ = type;
	}
	| FLOAT
	{
		//printf("inside float\n");
		//printf("At line no: %d type_specifier : FLOAT\n\n", lineCnt);
		fprintf(logFile, "At line no: %d type_specifier : FLOAT\n\n", lineCnt);
		fprintf(logFile, "float\n\n");
		symbolInfo *type = new symbolInfo("float", "FLOAT");
		$$ = type;
		//printf("Exiting Float\n");
	}
	| VOID
	{
		fprintf(logFile, "At line no: %d type_specifier : VOID\n\n", lineCnt);
		fprintf(logFile, "void\n\n");
		symbolInfo *type = new symbolInfo("void", "VOID");
		$$ = type;
	}
	;
 		
declaration_list : declaration_list COMMA ID
	{
		if (table->LookUpInCurrent($3->getName()) != nullptr)
		{
			//printf("%s\n", $3->getName().c_str());
			fprintf(errorFile, "Line no %d : Multiple declaration of %s\n\n", lineCnt, $3->getName().c_str());
			fprintf(logFile, "Error at line %d : Multiple declaration of %s\n\n", lineCnt, $3->getName().c_str());
			SMNTC_ERR_COUNT++;
		}

		fprintf(logFile, "At line no: %d declaration_list : declaration_list COMMA ID\n\n", lineCnt);
		fprintf(logFile, "%s, %s\n\n", $1->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+", "+$3->getName(), "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = "-1"; // -1 for variable only;

		var_vect.push_back(varPtr);
		$$=si;

	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		if (table->LookUpInCurrent($3->getName()) != nullptr)
		{
			//printf("%s\n", $3->getName().c_str());
			fprintf(errorFile, "Line no %d : Multiple declaration of %s\n\n", lineCnt, $3->getName().c_str());
			fprintf(logFile, "Error at line %d : Multiple declaration of %s\n\n", lineCnt, $3->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		
		/* declaration of array */
		fprintf(logFile, "At line no: %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s, %s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str(), $5->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+", "+$3->getName()+"["+$5->getName()+"]", "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = $5->getName(); // size for array variable
		var_vect.push_back(varPtr); 
		$$=si;
		
	}
	| ID
	{
		//printf("ID recog\n");
		fprintf(logFile, "At line no: %d declaration_list : ID\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = "-1"; // -1 for variable only;

		var_vect.push_back(varPtr);
		//printf("Exit ID\n");
		if (table->LookUpInCurrent($1->getName()) != nullptr)
		{
			
			fprintf(errorFile, "Line no %d : Multiple declaration of %s\n\n", lineCnt, $1->getName().c_str());
			fprintf(logFile, "Error at line %d : Multiple declaration of %s\n\n", lineCnt, $1->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		
	}
	| ID LTHIRD CONST_INT RTHIRD
	{
		if (table->LookUpInCurrent($1->getName()) != nullptr)
		{
			//char st[10];
			//sprintf(st, "%d", $1->getArrSize());
			//printf("%s=%s\n", $1->getName().c_str(), st);
			//printf("array %s = %s\n", $1->getName().c_str(), $1->getIdType().c_str());
			fprintf(errorFile, "Line no %d : Multiple declaration of %s\n\n", lineCnt, $1->getName().c_str());
			fprintf(logFile, "Error at line %d : Multiple declaration of %s\n\n", lineCnt, $1->getName().c_str());
			SMNTC_ERR_COUNT++;
		}

		/* declaration of array */
		fprintf(logFile, "At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+"["+$3->getName()+"]", "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = $3->getName(); // size for array variable
		var_vect.push_back(varPtr); 
		si->setArrSize(atoi($3->getName().c_str()));
		si->setIdType("array");
		$$=si;
		//printf("in array declaration , size = %d\n", atoi(varPtr->var_size.c_str()));
		
	}
	| declaration_list error
	{
		printf("printing declaration error\n");
		printf("error-> %s\n", $1->getName().c_str());
		yyclearin; //yyerrok;
		$$ = $1;
		//table->printAllScopeTable();
	}
	;
 		  
statements : statement
	{
		fprintf(logFile, "At line no: %d statements : statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setName($1->getName()+"\n");
		$$->setType("statements");
	}
	| statements statement
	{
		fprintf(logFile, "At line no: %d statements : statements statement\n\n", lineCnt);
		fprintf(logFile, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str());
		$$=new symbolInfo($1->getName() + $2->getName()+"\n", "statements"); // needs further checking 
	}
	| statements error_statement
	{
		//fprintf(logFile, "At line no: %d statements : statements statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		printf("Converging into statements\n");
	}
	;
	   
statement : var_declaration
	{
		fprintf(logFile, "At line no: %d statement : var_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1; $$->setType("statement");
	}
	| expression_statement
	{
		fprintf(logFile, "At line no: %d statement : expression_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;$$->setType("statement");
	}
	| compound_statement
	{
		fprintf(logFile, "At line no: %d statement : compound_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;$$->setType("statement");
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		fprintf(logFile, "At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "for("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;$$->setType("statement");
	}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		fprintf(logFile, "At line no: %d statement : IF LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;$$->setType("statement");
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		fprintf(logFile, "At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getName()+"else "+$7->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| WHILE LPAREN expression RPAREN statement
	{
		fprintf(logFile, "At line no: %d statement : WHILE LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "while("+$3->getName()+")"+$5->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineCnt);
		std::string statementC = "println("+$3->getName()+")"+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());

		// check if the declared ID is declared or not
		symbolInfo *x = table->LookUpInAll($3->getName());
		if (x == nullptr)
		{
			fprintf(errorFile, "Line no %d : Undeclared variable %s\n\n", lineCnt, $3->getName().c_str());
			fprintf(logFile, "Error at line %d : Undeclared variable %s\n\n", lineCnt, $3->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| PRINTF LPAREN ID RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no: %d statement : PRINTF LPAREN ID RPAREN SEMICOLON\n\n", lineCnt);
		std::string statementC = "printf("+$3->getName()+")"+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		
		// check if the declared ID is declared or not
		symbolInfo *x = table->LookUpInAll($3->getName());
		if (x == nullptr)
		{
			fprintf(errorFile, "Line no %d : Undeclared variable %s\n\n", lineCnt, $3->getName().c_str());
			fprintf(logFile, "Error at line %d : Undeclared variable %s\n\n", lineCnt, $3->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| RETURN expression SEMICOLON
	{
		fprintf(logFile, "At line no: %d statement : RETURN expression SEMICOLON\n\n", lineCnt);
		std::string statementC = "return "+$2->getName()+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");

		if ($2->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

		return_type = $2->getVarType();
	}
	;

error_statement : error_expression
	{
		printf("error_statement : error_expression\n");
		$$ = $1;
	};

expression_statement : SEMICOLON			
	{
		fprintf(logFile, "At line no: %d expression_statement : SEMICOLON\n\n", lineCnt);
		fprintf(logFile, ";\n\n");

		symbolInfo *si = new symbolInfo(";", "expression_statement");
		$$ = si;
		//type = "int";
	}
	| expression SEMICOLON
	{
		fprintf(logFile, "At line no: %d expression_statement : expression SEMICOLON\n\n", lineCnt);
		fprintf(logFile, "%s;\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName() + ";", "expression_statement");
		si->setVarType($1->getVarType());
		$$=si;
	}
	; 

error_expression : rel_expression error
	{
		printf("rel_expression_error : rel_expression error => %s error\n", $1->getName().c_str());
		//yyclearin; // clears the stack pointer 
		yyerrok; // permission to call error
		symbolInfo *si = new symbolInfo(
			$1->getName(),
			"error_expression"
		);
		$$=si;
	}
	| variable ASSIGNOP logic_expression error 
	{
		printf("variable ASSIGNOP logic_expression_error\n");
		printf("%s = %s\n", $1->getName().c_str(), $3->getName().c_str());
		$$ = new symbolInfo("" , "expression");
		//yyclearin; 
		yyerrok;
	}
	| simple_expression ADDOP error 
	{
		printf("error_expression : simple_expression ADDOP error\n");
		yyclearin; // clears the stack pointer 
		yyerrok; // permission to call error
		symbolInfo *si = new symbolInfo(
			$1->getName(),
			"error_expression"
		);
		$$=si;
	}
	| simple_expression RELOP error
	{
		printf("error_expression : simple_expression RELOP error\n");
		//yyclearin; // clears the stack pointer 
		yyerrok; // permission to call error
		symbolInfo *si = new symbolInfo(
			$1->getName(),
			"error_expression"
		);
		$$=si;
	}
	| error
	{
		printf("single error detected");
		$$ = new symbolInfo("", "error");
	}
	;


/* error_expression : expression 
	{
		printf("error_expression: expression\n");
		yyerrok; yyclearin;
		$$=new symbolInfo("", "");
	}
	| variable ASSIGNOP simple_expression_error
	{
		printf("expression dumping state\n");
		printf("%s = %s\n", $1->getName().c_str(), $3->getName().c_str());
		$$ = new symbolInfo("" , "expression");
		yyclearin; yyerrok;
	}
	| simple_expression_error
	{
		printf("error_expression : dump_simple_expr\n");
		$$=$1;
	}
	; */

/* 
error_expression : variable ASSIGNOP dump_simple_expr
	{
		printf("expression dumping state\n");
		printf("%s = %s\n", $1->getName().c_str(), $3->getName().c_str());
		$$ = new symbolInfo("" , "expression");
		yyclearin; yyerrok;
	}
	| dump_simple_expr
	{
		printf("error_expression : dump_simple_expr\n");
		$$=$1;
	}
	; */

	  


variable : ID 		
	{
		fprintf(logFile, "At line no: %d variable : ID\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());

		$$ = $1;
		$$->setIdType("variable");

		// check if this variable already exists in symbol table
		symbolInfo *x = table->LookUpInAll($$->getName());
		if (x) 
		{
			$$->setVarType(x->getVarType()); // variable declaration is okay
		}
		else 
		{
			fprintf(errorFile, "Line no %d : Undeclared variable %s\n\n", lineCnt, $$->getName().c_str());
			fprintf(logFile, "Error at line %d : Undeclared variable %s\n\n", lineCnt, $$->getName().c_str());
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}

		if (x != nullptr && x->getArrSize()!=-1)
		{
			fprintf(errorFile, "Line no %d : Type mismatch, %s is an array\n\n", lineCnt, x->getName().c_str());
			fprintf(logFile, "Error at line %d : Type mismatch, %s is an array\n\n", lineCnt, x->getName().c_str());
			SMNTC_ERR_COUNT++;
		}
		//printf("%s\n", $1->getName().c_str());
	}
	| ID LTHIRD expression RTHIRD 
	{
		fprintf(logFile, "At line no: %d variable : ID LTHIRD expression RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str());

		//check if expression(index) is int
		if ($3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			fprintf(errorFile, "Line no %d : Expression inside third brackets not an integer\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Expression inside third brackets not an integer\n\n", lineCnt);
		}

		// check if expression is calling void function
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

		symbolInfo *si = new symbolInfo(
			$1->getName() + "[" + $3->getName() + "]",
			"variable"
		);
		
		si->setIdType("array");
		symbolInfo *sts = table->LookUpInAll($1->getName());
		//printf("variable sts check  name == %s, size = %d type==%s\n", sts->getName().c_str(), sts->getArrSize(), sts->getIdType().c_str());
		if (sts == nullptr) {
			fprintf(errorFile, "Line no %d : Undeclared variable %s\n\n", lineCnt, $$->getName().c_str());
			fprintf(logFile, "Error at line %d : Undeclared variable %s\n\n", lineCnt, $$->getName().c_str());
			SMNTC_ERR_COUNT++;
			si->setVarType("int");
		}
		else if (sts->getIdType() != "array" || sts->getArrSize() == -1) // checking if array or not
		{
			//printf("error here in sts\n");
			fprintf(errorFile, "Line no %d : Type mismatch(not array)\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Type mismatch(not array)\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
		else 
		{
			si->setVarType(sts->getVarType());
			int index = atoi($3->getName().c_str());
			//printf("%s\n", $3->getVarType().c_str());
			if (index>=sts->getArrSize() && $3->getVarType()=="int")
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Array index out of bound\n\n", lineCnt);
				fprintf(logFile, "Error at line %d : Array index out of bound\n\n", lineCnt);
			}
			else si->arrIndex = index;
			si->setArrSize(sts->getArrSize());
		}
		$$=si;

	}
	;


 expression : logic_expression 
	{
		fprintf(logFile, "At line no: %d expression : logic_expression\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("expression");
	}
	| variable ASSIGNOP logic_expression
	{
		fprintf(logFile, "At line no: %d expression : variable ASSIGNOP logic_expression\n\n", lineCnt);
		fprintf(logFile, "%s = %s\n\n", $1->getName().c_str(), $3->getName().c_str());
		
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$3->setType("int");
		}
		if ($1->getVarType() != $3->getVarType() ) {
			if ($1->getVarType() == "float" && $3->getVarType() != "void")
			{
				// do nothing
			}
			else
			{
				//printf("%s type=%s, %s type=%s\n",$1->getName().c_str(), $1->getVarType().c_str(), $3->getName().c_str(), $3->getVarType().c_str());
				fprintf(errorFile, "Line no %d : Type mismatch\n\n", lineCnt);
				fprintf(logFile, "Error at line %d : Type mismatch\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}
			
		}


		$$ = new symbolInfo($1->getName() + "=" + $3->getName(), "expression");
		std::string searchName;
		
		if (isNameOfArr($1->getName()))
		{
			searchName = stripArr($1->getName());
		}
		else
		{
			searchName = $1->getName();
		}
		//printf("%s\n", searchName.c_str());
		symbolInfo *x = table->LookUpInAll(searchName);
		if (x==nullptr) {
			//fprintf(errorFile, "Line no %d : Variable not declared in this scope\n\n", lineCnt);
			//SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}
		else {
			$$->setVarType(x->getVarType());
		}
		type = $1->getVarType(); 
	}
	;

/* logic_expression_error : logic_expression error
	{
		printf("logic_expression_error : logic_expression error => %s error\n", $1->getName().c_str());
		yyclearin; // clears the stack pointer 
		yyerrok; // permission to call error
		symbolInfo *si = new symbolInfo(
			$1->getName(),
			"logic_expression_error"
		);
		$$=si;
	}
	| rel_expression LOGICOP rel_expression_error
	{
		printf("logic_expression_error : logic_expression error => %s error\n", $1->getName().c_str());
		//yyclearin; // clears the stack pointer 
		yyerrok; // permission to call error
		symbolInfo *si = new symbolInfo(
			$1->getName() + $2->getName(),
			"logic_expression_error"
		);
		$$=si;
	}
	; */

logic_expression : rel_expression 	
	{
		fprintf(logFile, "At line no: %d logic_expression : rel_expression\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("logic_expression");
		printf("%s\n", $$->getName().c_str());
	}
	| rel_expression LOGICOP rel_expression 	
	{
		fprintf(logFile, "At line no: %d logic_expression : rel_expression LOGICOP rel_expression\n\n", lineCnt);
		fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
				$2->getName().c_str(), $3->getName().c_str());
		
		/* type check */
		if ($1->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
		/* Not exactly necessary, because rel_expression is set to int in shifting procedure */
		if ($1->getVarType() != "int" || $3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			fprintf(errorFile, "Line no %d : Non-Integer operand in relational operator\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Non-Integer operand in relational operator\n\n", lineCnt);
		}
		symbolInfo *si = new symbolInfo(
			$1->getName() + $2->getName() + $3->getName(),
			"logic_expression"
		);
		si->setVarType("int");
		$$=si;
	}
	;


rel_expression	: simple_expression 
	{
		fprintf(logFile, "At line no: %d rel_expression : simple_expression\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("rel_expression");
	}
	| simple_expression RELOP simple_expression
	{
		fprintf(logFile, "At line no: %d rel_expression : simple_expression RELOP simple_expression\n\n", lineCnt);
		fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
				$2->getName().c_str(),
				$3->getName().c_str());

		/* checking function call */
		if ($1->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

		// if ($1->getVarType() != "int" || $3->getVarType() != "int")  // abandoned for not included in test cases
		// {
		// 	SMNTC_ERR_COUNT++;
		// 	fprintf(errorFile, "Line no %d : Non-Integer operand in RELOP operation\n\n", lineCnt);
		// 	fprintf(logFile, "Error at line %d : Non-Integer operand in RELOP operation\n\n", lineCnt);
		// }
		symbolInfo *si = new symbolInfo(
			$1->getName()+$2->getName()+$3->getName(),
			"rel_expression"
		);
		si->setVarType("int");
		$$=si;
	}
	;

				
simple_expression : term 
	{
		fprintf(logFile, "At line no: %d simple_expression : term\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("simple_expression");
	}
	| simple_expression ADDOP term 
	{
		fprintf(logFile, "At line no: %d simple_expression : simple_expression ADDOP term\n\n", lineCnt);
		fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
			$2->getName().c_str(),
			$3->getName().c_str());
		symbolInfo *si = new symbolInfo(
			$1->getName() + $2->getName() + $3->getName(),
			"simple_expression"
		);
		$$=si;
		
		/* type check */
		if ($1->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$1->setVarType("int");
		}
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$3->setVarType("int");
		}

		if ($1->getVarType() == "float" || $3->getVarType() == "float")
		{
			$$->setVarType("float");
		}
		else $$->setVarType("int");
	}
	;
					
term :	unary_expression
	{
		fprintf(logFile, "At line no: %d term : unary_expression\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("term");
	}
	|  term MULOP unary_expression
	{
		fprintf(logFile, "At line no: %d term : term MULOP unary_expression\n\n", lineCnt);
		fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo(
			$1->getName() + $2->getName() + $3->getName(),
			"term"
		);
		$$=si;
		// checking for MULOP(%) mismatch
		if ($1->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$1->setVarType("int");
		}
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$3->setVarType("int");
		}
		
		if ($2->getName() == "%") 
		{
			$$->setVarType("int");
			if ($1->getVarType() != "int" || $3->getVarType() != "int")
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Non-Integer operand on modulus operator\n\n", lineCnt);
				fprintf(logFile, "Error at line %d : Non-Integer operand on modulus operator\n\n", lineCnt);
			}
			if ($3->getName() == "0")
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Modulus by Zero\n\n", lineCnt);
				fprintf(logFile, "Error at line %d : Modulus by Zero\n\n", lineCnt);	
			}
		}
		else 
		{
			if ($3->getVarType() == "float" || $1->getVarType() == "float")
			{
				$$->setVarType("float");
			}
			else $$->setVarType("int");
		}
	}
	;

unary_expression : ADDOP unary_expression  
	{
		fprintf(logFile, "At line no: %d unary_expression : ADDOP unary_expression\n\n", lineCnt);
		fprintf(logFile, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+$2->getName(), "unary_expression");
		if ($2->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			si->setVarType("int");
		}
		else {
			si->setVarType($2->getVarType());
		}
		$$=si;
	}
	| NOT unary_expression 
	{
		fprintf(logFile, "At line no: %d unary_expression : NOT unary_expression\n\n", lineCnt);
		fprintf(logFile, "!%s\n\n", $2->getName().c_str());
		symbolInfo *si = new symbolInfo("!"+$2->getName(), "unary_expression");
		if ($2->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			si->setVarType("int");
		}
		else {
			si->setVarType($2->getVarType());
		}
		$$=si;
	}
	| factor 
	{
		fprintf(logFile, "At line no: %d unary_expression : factor\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("unary_expression");
	}
	;

factor	: variable 
	{
		fprintf(logFile, "At line no: %d factor : variable\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("factor");
	}
	| ID LPAREN argument_list RPAREN
	{
		fprintf(logFile, "At line no: %d factor : ID LPAREN argument_list RPAREN\n\n", lineCnt);
		fprintf(logFile, "%s(%s)\n\n", $1->getName().c_str(), $3->getName().c_str());
		//printf("%s\n", $1->getName().c_str());
		/* unfinished - check if function and arguments list match*/
		$$ = new symbolInfo($1->getName() + "(" + $3->getName() + ")", "factor");
		symbolInfo *x = table->LookUpInAll($1->getName());
		//printf("Function retrieved = %s\n", $1->getName().c_str());
		//printf("type = %s,\n", x->getType().c_str());
		// if (x->getFunctionInfo() == nullptr)
		// {
		// 	printf("not func pointer\n");
		// }
		/* Check if the function name exists*/
		if (x == nullptr) {
			fprintf(errorFile, "Line no %d : Undeclared/undefined function name %s\n\n", lineCnt, $1->getName().c_str());
			fprintf(logFile, "Error at line %d : Undeclared/undefined function name %s\n\n", lineCnt, $1->getName().c_str());
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}
		else if (x->getIdType() != "function" || x->getFunctionInfo() == nullptr)
		{
			fprintf(errorFile, "Line no %d : Type mismatch, %s not a function\n\n", lineCnt, x->getName().c_str());
			fprintf(logFile, "Error at line %d : Type mismatch, %s not a function\n\n", lineCnt, x->getName().c_str());
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}
		else 
		{ 
			/* match argument with param list */
			if(x->getParamSize() == 0) // if function doesnt have any parameter
			{
				 // needs to be implemented
			}
			else if (x->getParamSize() != arg_vect.size()) 
			{
				// parameter size does not match
				fprintf(errorFile, "Line no %d : Parameter and argument size does not match for function %s\n\n", lineCnt, x->getName().c_str());
				fprintf(logFile, "Error at line %d : Parameter and argument size does not match for function %s\n\n", lineCnt, x->getName().c_str());
				SMNTC_ERR_COUNT++;
				$$->setVarType("int");
			}
			else
			{
				// check every parameter type
				int i;
				for(i = 0; i<arg_vect.size();i++)
				{
					if (x->getParamAt(i)->param_type != arg_vect[i]->getVarType())
					{
						fprintf(errorFile, "Line no %d : Type mismatch (between argument and parameter) for %s\n\n", lineCnt, x->getName().c_str());
						fprintf(logFile, "Error at line %d : Type mismatch (between argument and parameter) for %s\n\n", lineCnt, x->getName().c_str());
						SMNTC_ERR_COUNT++;
						$$->setVarType("int");
						break;
					}
				}
				//printf("i val = %d\n", i);
				$$->setVarType(x->getVarType());
				// if (i!=arg_vect.size())
				// {
				// 	fprintf(errorFile, "Line no %d : Type mismatch (between argument and parameter) for %s\n\n", lineCnt, x->getName().c_str());
				// 	fprintf(logFile, "Error at line %d : Type mismatch (between argument and parameter) for %s\n\n", lineCnt, x->getName().c_str());
				// 	SMNTC_ERR_COUNT++;
				// }
			}
			
		}
		arg_vect.clear();
	}
	| LPAREN expression RPAREN
	{
		fprintf(logFile, "At line no: %d factor : LPAREN expression RPAREN\n\n", lineCnt);
		fprintf(logFile, "(%s)\n\n", $2->getName().c_str());
		symbolInfo *si = new symbolInfo("("+$2->getName()+")", "factor");
		$$=si;
		$$->setVarType($2->getVarType());
	}
	| CONST_INT 
	{
		fprintf(logFile, "At line no: %d factor : CONST_INT\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setVarType("int");
	}
	| CONST_FLOAT
	{
		fprintf(logFile, "At line no: %d factor : CONST_FLOAT\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setVarType("float");
	}
	| variable INCOP 
	{
		fprintf(logFile, "At line no: %d factor : variable INCOP\n\n", lineCnt);
		fprintf(logFile, "%s++\n\n", $1->getName().c_str());
		$$ = new symbolInfo($1->getName()+"++", "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	| variable DECOP 
	{
		fprintf(logFile, "At line no: %d factor : variable DECOP\n\n", lineCnt);
		fprintf(logFile, "%s--\n\n", $1->getName().c_str());
		$$ = new symbolInfo($1->getName()+"--", "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	;
	
argument_list : arguments
	{
		fprintf(logFile, "At line no: %d argument_list : arguments\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("argument_list");
	}
	|
	{
		fprintf(logFile, "At line no: %d argument_list : <epsilon>\n\n", lineCnt);
		fprintf(logFile, "\n\n");
		symbolInfo *si = new symbolInfo("", "argument_list");
		$$=si;
	}
	;
	
arguments : arguments COMMA logic_expression
	{
		fprintf(logFile, "At line no: %d arguments : arguments COMMA logic_expression\n\n", lineCnt);
		fprintf(logFile, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+","+$3->getName(), "arguments");
		if ($1->getVarType() == "void")
		{
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$1->setVarType("int");
		}
		$$ = si;
		arg_vect.push_back($3);
	}
	| logic_expression
	{
		fprintf(logFile, "At line no: %d arguments : logic_expression\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=new symbolInfo($1->getName(), "arguments");
		if ($1->getVarType() == "void")
		{
			fprintf(errorFile, "Line no %d : Void function call within expression\n\n", lineCnt);
			fprintf(logFile, "Error at line %d : Void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$1->setVarType("int");
		}
		
		$$->setType("arguments");
		arg_vect.push_back($1);
	}
	;


%%
int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logFile= fopen(argv[2],"w");
	//fclose(logFile);
	errorFile= fopen(argv[3],"w");
	//fclose(errorFile);
	
	//logFile= fopen(argv[2],"a");
	//errorFile= fopen(argv[3],"a");
	
	//printf("Parsing\n");
	yyin=fp;
	table = new SymbolTable(6);
	table->setFileWriter(logFile);
	yyparse();
	//printf("end Parsing\n");
	

	fprintf(logFile, "\t\t Symbol Table:\n\n");
	table->printAllScopeTable();
	fprintf(logFile, "Total Lines: %d\n\n", lineCnt-1); // lineCnt decreased to encounter false increment
	fprintf(logFile, "Total Errors: %d\n\n", SMNTC_ERR_COUNT+ERR_COUNT);
	fclose(yyin);
	fclose(logFile);
	fclose(errorFile);
	
	return 0;
}

