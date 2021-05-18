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
std::string err_segm;
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
std::string current_return_type;

// defined functions

void writeToLog(std::string msg, bool lineSt = true, bool doubleGap=true)
{
	if (lineSt)
	{
		if (doubleGap)fprintf(logFile, "Line %d: %s\n\n", lineCnt, msg.c_str());
		else fprintf(logFile, "Line %d: %s\n", lineCnt, msg.c_str());
	}
	else
	{
		if (doubleGap)fprintf(logFile, "%s\n\n", msg.c_str());
		else fprintf(logFile, "%s\n", msg.c_str());
	}
}

void writeError(std::string msg, bool writeOnAll = true)
{
	if(writeOnAll)
	{
		fprintf(errorFile, "Error at line %d: %s\n\n", lineCnt, msg.c_str());
		fprintf(logFile, "Error at line %d: %s\n\n", lineCnt, msg.c_str());
	}
	else
	{
		fprintf(errorFile, "Error at line %d: %s\n\n", lineCnt, msg.c_str());
	}
}

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
		f->onlyDeclared = false;
		std::vector<param*> param_list;

		for (int i=0;i<temp_param_list.size();i++)
		{
			if (temp_param_list[i]->param_type != "void")
			{
				param_list.push_back(temp_param_list[i]);
			}
		}
		f->param_list = param_list;
		//printf("inserting func name %s into table at line %d\n", funcName.c_str(), lineCnt);
		insertFuncIntoTable(funcName, f);
	}
	else if (x->getIdType()!="function")
	{
		err_segm = "Multiple declaration of " + funcName;
		writeError(err_segm);
		SMNTC_ERR_COUNT++;
	}
	else if (!x->hasFuncPtr())
	{
		writeError("Function "+funcName+" previously defined but not properly structured");
		SMNTC_ERR_COUNT++;
	}
	else if (!x->funcDeclNotDef())
	{
		writeError("Multiple definitions of function " + funcName);
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
			writeError("Return type mismatch with function declaration in function " + funcName);
			SMNTC_ERR_COUNT++;
		}
		else if (x->getParamSize() == 1 && temp_param_list.size()==0 && x->getParamAt(0)->param_type == "void")
		{
			// function previously declared with param void
			// No param in function def is given
			x->getFunctionInfo()->onlyDeclared = false;
		}
		else if (x->getParamSize() == 0 && temp_param_list.size()==1 && temp_param_list[0]->param_type == "void")
		{
			// function previously declared with no param
			// void is given as param in definition
			x->getFunctionInfo()->onlyDeclared = false;
		}
		else
		{
			// check parameter consistency
			//printf("for function %s, def_size = %d\n", x->getName().c_str(), x->getParamSize());

			if (x->getParamSize() != temp_param_list.size())
			{
				writeError("Total number of arguments mismatch with declaration in function " + x->getName());
				SMNTC_ERR_COUNT++;
			}
			else
			{
				int i;
				for (i=0; i<temp_param_list.size(); i++)
				{
					if (temp_param_list[i]->param_type != x->getParamAt(i)->param_type)
					{
						err_segm = "Parameter type mismatch, expected " + x->getParamAt(i)->param_type +
							", given " + temp_param_list[i]->param_type;
						writeError(err_segm);
						SMNTC_ERR_COUNT++;
						break;
					}
				}
				if (i == temp_param_list.size())
				{
					x->getFunctionInfo()->onlyDeclared = false;
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
		f->onlyDeclared = true;
		f->param_list = temp_param_list;
		insertFuncIntoTable(funcName, f);
	}
	else
	{
		writeError("Multiple definitions for function " + funcName);
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

bool isNumber(std::string str)
{
	std::regex b("[0-9]+");
	return std::regex_match(str, b);
}

bool voidFuncCall(std::string Type)
{
	bool isVoid = (Type == "void")? true:false;
	if (isVoid)
	{
		/* void function cannot be called in expression */
		writeError("Void function used in expression");
		SMNTC_ERR_COUNT++;
	}
	return isVoid;
}

void yyerror(char *s)
{
	ERR_COUNT++;
	fprintf(logFile, "Error at Line %d: %s\n\n", lineCnt, s);
	fprintf(errorFile, "Error at Line %d: %s\n\n", lineCnt, s);
}


%}

%union {
	symbolInfo *symbol;
}

%token IF ELSE FOR WHILE DO INT CHAR FLOAT DOUBLE VOID RETURN
%token DEFAULT CONTINUE ASSIGNOP LPAREN RPAREN LCURL RCURL
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

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		fprintf(logFile, "Line %d: start : program\n\n", lineCnt-1);// lineCnt is decreased by 1
												//because it read the last newline of input file and falsely incremented line count
		/* for (auto str : code_vect)
		{
			writeToLog(str, false);
		}
		writeToLog("\n", false); */
	}
	;

program : program unit
	{
		writeToLog("program : program unit");
		code_vect.push_back($2->getName());
		for(int i = 0; i < code_vect.size(); i++)
		{
			writeToLog(code_vect[i], false, false);
		}
		writeToLog("", false, false);
	}
	| unit
	{
		writeToLog("program : unit");
		writeToLog($1->getName(), false);
		code_vect.push_back($1->getName());
		// shouldnt there be print here also
	}
	;

unit : var_declaration
	{
		writeToLog("unit : var_declaration");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
	}
	| func_declaration
	{
		writeToLog("unit : func_declaration");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
	}
	| func_definition
	{
		writeToLog("unit : func_definition");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
	}
	;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		code_segm = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ");";
		writeToLog("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_declaration");
		checkFunctionDec($2->getName(), $1->getName());
		temp_param_list.clear();
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		code_segm = $1->getName() + " " + $2->getName() + "(" + ");" ;
		writeToLog("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_declaration");
		checkFunctionDec($2->getName(), $1->getName());
		temp_param_list.clear();
	}
	;

func_definition : func_definition_initP compound_statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_definition");
		$$->setVarType($1->getVarType());
	}
	| func_definition_init compound_statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_definition");
		$$->setVarType($1->getVarType());
	}
	;

func_definition_initP : type_specifier ID LPAREN parameter_list RPAREN
	{
		checkFunctionDef($2->getName(), $1->getName());
		code_segm = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ")";
		$$ = new symbolInfo(code_segm, "func_definition_initP");
		$$->setVarType($1->getName());
		current_return_type = $1->getName();
	};

func_definition_init : type_specifier ID LPAREN RPAREN
	{
		checkFunctionDef($2->getName(), $1->getName());
		code_segm = $1->getName() + " " + $2->getName() + "()";
		$$ = new symbolInfo(code_segm, "func_definition_init");
		$$->setVarType($1->getName());
		current_return_type = $1->getName();
	};

parameter_list  : parameter_list COMMA type_specifier ID
	{
		code_segm = $1->getName() + "," + $3->getName() + " " + $4->getName();
		
		// if the current parameter is a duplicate, it will not be inserted 
		// into parameter list 
		bool duplicate = false;

		// if the typespecifier is void, subsequent errors will not be counted
		// because the parameter list error would be unfairly penalized
		// voidType variable is thus used to record
		bool voidType = false; 
		// checking if type specifier is void
		if ($3->getName() == "void")
		{
			writeError("Parameter type cannot be void");
			SMNTC_ERR_COUNT++;
			voidType = true;
		}

		// There can be multiple declarations of a parameter inside param_list
		// Multiple declarations of same param raises error

		for (int i=0; i<temp_param_list.size(); i++)
		{
			// if ID name ($4) matches an already exisitng paramerter 
			if (temp_param_list[i]->param_name == $4->getName())
			{
				// if the type is the same for both duplicates
				if (temp_param_list[i]->param_type == $3->getName())
				{
					err_segm = "Multiple declaration of " + $4->getName() + " in parameter";
					writeError(err_segm);
					if (!voidType) SMNTC_ERR_COUNT++;
				}
				else
				{
					err_segm = "Multiple declaration of " + $4->getName() + " (as type " + temp_param_list[i]->param_type +
								" and " + $3->getName() + ") in parameter";
					writeError(err_segm);
					if (!voidType) SMNTC_ERR_COUNT++;
				}
				duplicate = true;
			}
		}
		$$ = new symbolInfo(code_segm, "parameter_list");
		if (!duplicate && !voidType)
		{
			p = new param;
			p->param_type = $3->getName();
			p->param_name = $4->getName();
			temp_param_list.push_back(p);
		}
		writeToLog("parameter_list : parameter_list COMMA type_specifier ID");
		writeToLog(code_segm, false);
	}
	| parameter_list COMMA type_specifier
	{
		code_segm = $1->getName() + "," + $3->getName();
		writeToLog("parameter_list : parameter_list COMMA type_specifier");

		$$ = new symbolInfo(code_segm, "parameter_list");
		p = new param;
		p->param_type = $3->getName();
		p->param_name = "";
		if ($3->getName() == "void" && temp_param_list.size()>0)
		{
			writeError("Invalid use of void in parameter");
			SMNTC_ERR_COUNT++;
		}
		else temp_param_list.push_back(p);
		writeToLog(code_segm, false);
	}
	| type_specifier ID
	{
		code_segm = $1->getName() + " " + $2->getName();
		writeToLog("parameter_list : type_specifier ID");

		$$ = new symbolInfo(code_segm, "parameter_list");
		p = new param;
		p->param_type = $1->getName();
		p->param_name = $2->getName();
		if (temp_param_list.size() > 0)
		{
			temp_param_list.clear();
		}
		if ($1->getName() == "void")
		{
			writeError("Parameter type cannot be void");
			SMNTC_ERR_COUNT++;
		}
		else
		{
			temp_param_list.push_back(p);
		}
		writeToLog(code_segm, false);
	}
	| type_specifier
	{
		writeToLog("parameter_list : type_specifier");
		writeToLog($1->getName(), false);
		$$=$1; $$->setType("parameter_list");
		p = new param;
		p->param_type = $1->getName();
		p->param_name = "";
		if (temp_param_list.size() > 0)
		{
			temp_param_list.clear();
		}
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
		code_segm = "{\n"+$3->getName()+"}";
		writeToLog("compound_statement : LCURL statements RCURL");
		writeToLog(code_segm, false);

		$$ = new symbolInfo(code_segm, "compound_statement");
		table->printAllScopeTable();

		table->ExitScope();
		//current_return_type = "";
	}
	| LCURL interimScopeAct RCURL
	{
		code_segm = "{\n}";
		writeToLog("compound_statement : LCURL RCURL");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "compound_statement");
		table->printAllScopeTable();
		table->ExitScope();
		//current_return_type = "";

	}
	;

interimScopeAct :
	{
		table->EnterScope();
		if(temp_param_list.size()>1 ||
				(temp_param_list.size() == 1 &&
				temp_param_list[0]->param_type != "void" ))
		{
			for(int i=0;i<temp_param_list.size();i++)
			{
				p = temp_param_list[i];
				varPtr = new variableInfo;
				varPtr->var_name = p->param_name;
				varPtr->var_size = "-1"; // beacuse the grammar rule does not permit arrays to be parameter
				insertVarIntoTable(p->param_type, varPtr);
			}
		}
		temp_param_list.clear();
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
	{
		code_segm = $1->getName()+" "+$2->getName()+";";
		writeToLog("var_declaration : type_specifier declaration_list SEMICOLON");

		$$ =  new symbolInfo(code_segm, "var_declaration");
		std::string varType = $1->getName();
		if ($1->getType() == "VOID")
		{
			writeError("Variable type cannot be void");
			SMNTC_ERR_COUNT++;
			varType = "int"; // default var type int
		}
		else
		{
			// NOTICE : (changed) void variables are not inserted into SymbolTable
			for ( int i=0; i<var_vect.size(); i++)
			{
				insertVarIntoTable(varType, var_vect[i]);
				//printf("insert into table, %s\n", var_vect[i]->var_name.c_str());
			}
		}
		var_vect.clear();
		writeToLog(code_segm, false);
	}
	;

type_specifier : INT
	{
		writeToLog("type_specifier : INT"); writeToLog("int", false);
		$$ = new symbolInfo("int", "INT");
	}
	| FLOAT
	{
		writeToLog("type_specifier : FLOAT"); writeToLog("float", false);
		$$ = new symbolInfo("float", "FLOAT");
	}
	| VOID
	{
		writeToLog("type_specifier : VOID"); writeToLog("void", false);
		$$ = new symbolInfo("void", "VOID");
	}
	;

declaration_list : declaration_list COMMA ID
	{
		code_segm = $1->getName()+", "+$3->getName();
		writeToLog("declaration_list : declaration_list COMMA ID");
		writeToLog(code_segm, false);
		if (table->LookUpInCurrent($3->getName()) != nullptr)
		{
			err_segm = "Multiple declaration of " + $3->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}
		$$ = new symbolInfo(code_segm, "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = "-1"; // -1 for variable ID only;

		var_vect.push_back(varPtr);

	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		code_segm = $1->getName()+", "+$3->getName()+"["+$5->getName()+"]";
		writeToLog("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");

		if (table->LookUpInCurrent($3->getName()) != nullptr)
		{
			err_segm = "Multiple declaration of " + $3->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}

		/* declaration of array */
		$$ = new symbolInfo(code_segm, "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = $5->getName(); // size for array variable
		var_vect.push_back(varPtr);
		writeToLog(code_segm, false);
	}
	| ID
	{
		//printf("ID recog\n");
		writeToLog("declaration_list : ID");

		$$=$1;
		$$->setType("declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = "-1"; // -1 size for ID only;

		var_vect.push_back(varPtr);
		if (table->LookUpInCurrent($1->getName()) != nullptr)
		{
			err_segm = "Multiple declaration of " + $1->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}
		writeToLog($1->getName(), false);

	}
	| ID LTHIRD CONST_INT RTHIRD
	{
		/* declaration of array */
		code_segm = $1->getName()+"["+$3->getName()+"]";
		writeToLog("declaration_list : ID LTHIRD CONST_INT RTHIRD");

		if (table->LookUpInCurrent($1->getName()) != nullptr)
		{
			//char st[10];
			//sprintf(st, "%d", $1->getArrSize());
			//printf("%s=%s\n", $1->getName().c_str(), st);
			//printf("array %s = %s\n", $1->getName().c_str(), $1->getIdType().c_str());
			err_segm = "Multiple declaration of " + $1->getName();
			writeError(code_segm);
			SMNTC_ERR_COUNT++;
		}


		symbolInfo *si = new symbolInfo($1->getName()+"["+$3->getName()+"]", "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = $3->getName(); // size for array variable
		var_vect.push_back(varPtr);
		si->setArrSize(atoi($3->getName().c_str()));
		si->setIdType("array");
		$$=si;
		writeToLog(code_segm, false);
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
		writeToLog("statements : statement"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setName($1->getName()+"\n");
		$$->setType("statements");
	}
	| statements statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("statements : statements statement"); writeToLog(code_segm, false);
		$$=new symbolInfo(code_segm+"\n", "statements");
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
		writeToLog("statement : var_declaration"); writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| expression_statement
	{
		writeToLog("statement : expression_statement"); writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| compound_statement
	{
		writeToLog("statement : compound_statement"); writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		code_segm = "for("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getName();
		writeToLog("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");

		if (voidFuncCall($5->getVarType()))
		{
			/* void function cannot be called in expression */
			$5->setVarType("int"); // default type is int
		}
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		code_segm = "if("+$3->getName()+")"+$5->getName();
		writeToLog("statement : IF LPAREN expression RPAREN statement");

		if (voidFuncCall($3->getVarType()))
		{
			/* void function cannot be called in expression */
			$3->setVarType("int"); // default type is int
		}
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		code_segm = "if("+$3->getName()+")"+$5->getName()+"\nelse \n"+$7->getName();
		writeToLog("statement : IF LPAREN expression RPAREN statement ELSE statement");

		if (voidFuncCall($3->getVarType()))
		{
			/* void function cannot be called in expression */
			$3->setVarType("int"); // default type is int
		}

		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| WHILE LPAREN expression RPAREN statement
	{
		code_segm = "while("+$3->getName()+")"+$5->getName();
		writeToLog("statement : WHILE LPAREN expression RPAREN statement");

		if (voidFuncCall($3->getVarType()))
		{
			/* void function cannot be called in expression */
			$3->setVarType("int"); // default type is int
		}
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		code_segm = "println("+$3->getName()+")"+";";
		writeToLog("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");

		// check if the declared ID is declared or not
		symbolInfo *x = table->LookUpInAll($3->getName());
		if (x == nullptr)
		{
			err_segm = "Undeclared variable " + $3->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}
		else if (x->getIdType() != "variable")
		{
			err_segm = $3->getName() + " not a variable";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		} 
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| PRINTF LPAREN ID RPAREN SEMICOLON
	{
		code_segm = "printf("+$3->getName()+")"+";";
		writeToLog("statement : PRINTF LPAREN ID RPAREN SEMICOLON");

		// check if the declared ID is declared or not
		symbolInfo *x = table->LookUpInAll($3->getName());
		if (x == nullptr)
		{
			err_segm = "Undeclared variable " + $3->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}
		else if (x->getIdType() != "variable")
		{
			err_segm = $3->getName() + " not a variable";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		} 
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);
	}
	| RETURN expression SEMICOLON
	{
		code_segm = "return "+$2->getName()+";";
		writeToLog("statement : RETURN expression SEMICOLON");

		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");

		if (voidFuncCall($2->getVarType()))
		{
			/* void function cannot be called in expression */
			$2->setVarType("int"); // default type is int
		}

		return_type = $2->getVarType();
		if ($2->getVarType() != current_return_type)
		{
			SMNTC_ERR_COUNT++;
			err_segm = "Type mismatch, return type expected: " + current_return_type
						+ " found: " + $2->getVarType();
			writeError(err_segm);
		}
		writeToLog(code_segm, false);
	}
	;

error_statement : error_expression
	{
		printf("error_statement : error_expression\n");
		$$ = $1;
	};

expression_statement : SEMICOLON
	{
		writeToLog("expression_statement : SEMICOLON"); writeToLog(";", false);
		$$ = new symbolInfo(";", "expression_statement");
	}
	| expression SEMICOLON
	{
		code_segm = $1->getName() + ";";
		writeToLog("expression_statement : expression SEMICOLON");
		// commented out because of input4 mismatch 
		// if (voidFuncCall($1->getVarType()))
		// {
		// 	/* void function cannot be called in expression */
		// 	$1->setVarType("int");
		// }
		$$ = new symbolInfo(code_segm, "expression_statement");
		$$->setVarType($1->getVarType());
		writeToLog(code_segm, false);

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


variable : ID
	{
		writeToLog("variable : ID");
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
			err_segm = "Undeclared variable " + $$->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int"); // assign the default type int
		}

		if (x != nullptr && (x->getArrSize()!=-1 || x->getIdType() == "array"))
		{
			err_segm = "Type mismatch, " + x->getName() + " is an array";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
		}
		writeToLog($1->getName(), false);

	}
	| ID LTHIRD expression RTHIRD
	{
		code_segm = $1->getName() + "[" + $3->getName() + "]";
		writeToLog("variable : ID LTHIRD expression RTHIRD");

		symbolInfo *si = new symbolInfo(code_segm, "variable");
		si->setIdType("array");

		//check if expression(index) is int
		if ($3->getVarType() != "int" || !isNumber($3->getName()))
		{
			SMNTC_ERR_COUNT++;
			writeError("Expression inside third brackets not an integer");
		}

		/* void function cannot be called in expression */
		voidFuncCall($1->getVarType());

		symbolInfo *sts = table->LookUpInAll($1->getName());
		//printf("variable sts check  name == %s, size = %d type==%s\n", sts->getName().c_str(), sts->getArrSize(), sts->getIdType().c_str());
		if (sts == nullptr) {
			err_segm = "Undeclared variable " + $1->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			si->setArrSize(0);
			si->setVarType("int");
		}
		else if (sts->getIdType() != "array" || sts->getArrSize() == -1) // checking if array or not
		{
			err_segm = "Type mismatch, " + sts->getName() + " is not an array";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			si->setArrSize(0);
			si->setVarType("int");
		}
		else
		{
			si->setVarType(sts->getVarType());
			int index = ($3->getVarType()=="int")?atoi($3->getName().c_str()):0;
			//printf("%s\n", $3->getVarType().c_str());
			if (index>=sts->getArrSize() && $3->getVarType()=="int")
			{
				SMNTC_ERR_COUNT++;
				writeError("Array index out of bound");
			}
			else si->arrIndex = index;
			si->setArrSize(sts->getArrSize());
		}
		$$=si;
		writeToLog(code_segm, false);
	}
	;


 expression : logic_expression
	{
		writeToLog("expression : logic_expression"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("expression");
	}
	| variable ASSIGNOP logic_expression
	{
		code_segm = $1->getName() + "=" + $3->getName();
		writeToLog("expression : variable ASSIGNOP logic_expression");

		$$ = new symbolInfo(code_segm, "expression");
		$$->setVarType($1->getVarType());

		
		if (voidFuncCall($3->getVarType()))
		{
			/* void function cannot be called in expression */
			$3->setVarType("int");
		}
		else if ($1->getVarType() != $3->getVarType()) {
			// checking if the operands on both sides have same type
			// or if left operand has higher precedence than operand on right
			if (!($1->getVarType() == "float" && $3->getVarType() != "void"))
			{
				//printf("%s type=%s, %s type=%s\n",$1->getName().c_str(), $1->getVarType().c_str(), $3->getName().c_str(), $3->getVarType().c_str());
				writeError("Type Mismatch");
				SMNTC_ERR_COUNT++;
			}
		}

		

		// this part is abandoned because variable is already checked if
		// array or variable while reducing into variable from ID/ID [expr]

		// needs checking
		// std::string searchName;

		// if (isNameOfArr($1->getName()))
		// {
		// 	searchName = stripArr($1->getName());
		// }
		// else
		// {
		// 	searchName = $1->getName();
		// }
		// //printf("%s\n", searchName.c_str());
		// symbolInfo *x = table->LookUpInAll(searchName);
		// if (x==nullptr) {
		// 	//fprintf(errorFile, "Line no %d : Variable not declared in this scope\n\n", lineCnt);
		// 	//SMNTC_ERR_COUNT++;
		// 	$$->setVarType("int");
		// }

		type = $1->getVarType();
		writeToLog(code_segm, false);
	}
	;


logic_expression : rel_expression
	{
		writeToLog("logic_expression : rel_expression"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("logic_expression");
		//printf("%s\n", $$->getName().c_str()); // discard this
	}
	| rel_expression LOGICOP rel_expression
	{
		code_segm = $1->getName() + $2->getName() + $3->getName();
		writeToLog("logic_expression : rel_expression LOGICOP rel_expression");

		$$ = new symbolInfo(code_segm, "logic_expression");
		$$->setVarType("int");

		/* void function cannot be called in expression */
		voidFuncCall($1->getVarType());
		voidFuncCall($3->getVarType());
		writeToLog(code_segm, false);
		if ($1->getVarType() != "int" || $3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			writeError("Non-Integer operand in relational operator");
		}

	}
	;


rel_expression	: simple_expression
	{
		writeToLog("rel_expression : simple_expression"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("rel_expression");
	}
	| simple_expression RELOP simple_expression
	{
		code_segm = $1->getName()+$2->getName()+$3->getName();
		writeToLog("rel_expression : simple_expression RELOP simple_expression");

		$$ = new symbolInfo(code_segm, "rel_expression");
		$$->setVarType("int");

		/* void function cannot be called in expression */
		voidFuncCall($1->getVarType());
		voidFuncCall($3->getVarType());

		// if ($1->getVarType() != "int" || $3->getVarType() != "int")  // abandoned for not being included in test cases
		// {
		// 	SMNTC_ERR_COUNT++;
		// 	fprintf(errorFile, "Line no %d : Non-Integer operand in RELOP operation\n\n", lineCnt);
		// 	fprintf(logFile, "Error at line %d : Non-Integer operand in RELOP operation\n\n", lineCnt);
		// }
		writeToLog(code_segm, false);
	}
	;


simple_expression : term
	{
		writeToLog("simple_expression : term"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("simple_expression");
	}
	| simple_expression ADDOP term
	{
		code_segm = $1->getName() + $2->getName() + $3->getName();
		writeToLog("simple_expression : simple_expression ADDOP term");

		$$ = new symbolInfo(code_segm, "simple_expression");
		$$->setVarType("int");

		/* void function cannot be called in expression */
		voidFuncCall($1->getVarType());
		voidFuncCall($3->getVarType());

		if ($1->getVarType() == "float" || $3->getVarType() == "float")
		{
			$$->setVarType("float");
		}
		writeToLog(code_segm, false);
	}
	;

term :	unary_expression
	{
		writeToLog("term : unary_expression"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("term");
	}
	|  term MULOP unary_expression
	{
		code_segm = $1->getName() + $2->getName() + $3->getName();
		writeToLog("term : term MULOP unary_expression");

		$$ = new symbolInfo(code_segm, "term");
		$$->setVarType("int");

		/* void function cannot be called in expression */
		voidFuncCall($1->getVarType());
		voidFuncCall($3->getVarType());

		// checking for MULOP(%) mismatch
		if ($2->getName() == "%")
		{
			if ($1->getVarType() != "int" || $3->getVarType() != "int")
			{
				SMNTC_ERR_COUNT++;
				writeError("Non-Integer operand on modulus operator");
			}
			if ($3->getName() == "0")
			{
				SMNTC_ERR_COUNT++;
				writeError("Modulus by Zero");
			}
		}
		else
		{
			// type setting
			// if any operator on MULOP is float, then the result should be
			// type casted to float
			if ($3->getVarType() == "float" || $1->getVarType() == "float")
			{
				$$->setVarType("float");
			}
		}

		writeToLog(code_segm, false);
	}
	;

unary_expression : ADDOP unary_expression
	{
		code_segm = $1->getName()+$2->getName();
		writeToLog("unary_expression : ADDOP unary_expression");
		symbolInfo *si = new symbolInfo(code_segm, "unary_expression");
		if (voidFuncCall($2->getVarType()))
		{
			/* void function cannot be called in expression */
			si->setVarType("int");
		}
		else {
			si->setVarType($2->getVarType());
		}
		$$=si;
		writeToLog(code_segm, false);
	}
	| NOT unary_expression
	{
		code_segm = "!"+$2->getName();
		writeToLog("unary_expression : NOT unary_expression");
		$$ = new symbolInfo(code_segm, "unary_expression");

		/* void function cannot be called in expression */
		voidFuncCall($2->getVarType());
		$$->setVarType("int");
		writeToLog(code_segm, false);
	}
	| factor
	{
		writeToLog("unary_expression : factor"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("unary_expression");
	}
	;

factor	: variable
	{
		writeToLog("factor : variable"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("factor");
	}
	| ID LPAREN argument_list RPAREN
	{
		code_segm = $1->getName() + "(" + $3->getName() + ")";
		writeToLog("factor : ID LPAREN argument_list RPAREN");

		$$ = new symbolInfo(code_segm, "factor");
		symbolInfo *x = table->LookUpInAll($1->getName());

		/* Check if the function name exists*/
		if (x == nullptr) {
			err_segm = "Undeclared function " + $1->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int"); // default type int
		}
		else if (x->getIdType() != "function" || x->getFunctionInfo() == nullptr)
		{
			err_segm = "Type mismatch, " + x->getName() + " not a function";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int"); // default type int
		}
		else
		{
			// match argument with param list

			if (x->getParamSize() == 1 && arg_vect.size() == 0 && x->getParamAt(0)->param_type == "void")
			{
				// valid match
				// def foo(void)
				// call => foo();
				$$->setVarType(x->getVarType());
			}
			else if (x->getParamSize() != arg_vect.size())
			{
				// parameter size does not match
				err_segm = "Total number of arguments mismatch in function " + x->getName();
				writeError(err_segm);
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
						err_segm = (i+'1');
						if (i<=2)
						{
							if(i==0) err_segm+="st";
							else if (i==1)err_segm+="nd";
							else err_segm+="rd";
						}
						else err_segm+="th"; 
						
						err_segm += " argument mismatch in function " + x->getName();
						err_segm += "\n(expected "+x->getParamAt(i)->param_type +", ";
						err_segm += "found " + arg_vect[i]->getVarType() + ")";
						writeError(err_segm);
						SMNTC_ERR_COUNT++;
						//$$->setVarType("int");  // notice if error occurs!
						break; // error is shown only for one parameter
					}
				}
				//printf("i val = %d\n", i);
				$$->setVarType(x->getVarType());
			}

		}
		writeToLog(code_segm, false);
		arg_vect.clear(); // clearing current argument vector
	}
	| LPAREN expression RPAREN
	{
		code_segm = "(" + $2->getName() + ")";
		writeToLog("factor : LPAREN expression RPAREN");
		// voidFuncCall($2->getVarType());
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($2->getVarType());
	}
	| CONST_INT
	{
		writeToLog("factor : CONST_INT"); writeToLog($1->getName(), false);
		$$=$1;
		$$->setVarType("int");
	}
	| CONST_FLOAT
	{
		writeToLog("factor : CONST_FLOAT");
		std::string val = $1->getName();
		int i;
		for(i = 0; i<val.size();i++)
		{
			if(val[i]=='.') break;
		}
		// converting float numbers into atleast 2 numbers after decimal point
		if ((val.size()-1-i) == 1)val += "0";
		$$=$1;
		$$->setName(val);
		$$->setVarType("float");
		writeToLog(val, false);
	}
	| variable INCOP
	{
		code_segm = $1->getName() + "++";
		writeToLog("factor : variable INCOP"); writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	| variable DECOP
	{
		code_segm = $1->getName() + "--";
		writeToLog("factor : variable DECOP"); writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	;

argument_list : arguments
	{
		writeToLog("argument_list : arguments");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("argument_list");
	}
	|
	{
		writeToLog("argument_list : <epsilon>");
		writeToLog("", false);
		$$ = new symbolInfo("", "argument_list");
	}
	;

arguments : arguments COMMA logic_expression
	{
		writeToLog("arguments : arguments COMMA logic_expression");
		code_segm = $1->getName() + "," + $3->getName();
		$$ = new symbolInfo(code_segm, "arguments");
		if (voidFuncCall($3->getVarType()))
		{
			$3->setVarType("int");// default type is int
		}
		$$->setVarType($1->getVarType());
		writeToLog(code_segm, false);
		arg_vect.push_back($3); // arg_vect used to keep track of arguments
	}
	| logic_expression
	{
		writeToLog("arguments : logic_expression");

		$$=new symbolInfo($1->getName(), "arguments");
		if (voidFuncCall($1->getVarType()))
		{
			$1->setVarType("int");// default type is int
		}
		writeToLog($1->getName(), false);
		$$->setVarType($1->getVarType());
		arg_vect.push_back($1); // arg_vect used to keep track of arguments
	}
	;


%%

int main(int argc,char *argv[])
{

	if(argc<2)
	{
		printf("Input filenames not properly provided\n");
		printf("Proper Format:\n[input_filename] [log_file _name] [erro_file_name]\n\n");
		printf("Terminating program...\n");
		return 0;
	}

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\nTerminating program...\n");
		exit(1);
	}

	logFile = fopen(argv[2],"w");
	errorFile = fopen(argv[3],"w");

	// checking if logfile and error files are properly working
	if (logFile == nullptr)
	{
		printf("Log File not properly opened\nTerminating program...\n");
		fclose(logFile);
		exit(1);
	}

	if (errorFile == nullptr)
	{
		printf("Error File not properly opened\nTerminating program...\n");
		fclose(errorFile);
		exit(1);
	}

	yyin=fp; // assigning input file pointer to yyin
	table = new SymbolTable(30); // symbol table pointer assigned to table
	table->setFileWriter(logFile);

	// starting parsing
	yyparse();

	fprintf(logFile, "\t\t Symbol Table:\n\n");
	table->printAllScopeTable();
	fprintf(logFile, "Total Lines: %d\n\n", lineCnt-1);
				// lineCnt decreased to encounter false increment
	fprintf(logFile, "Total Errors: %d\n\n", SMNTC_ERR_COUNT+ERR_COUNT);

	// closing input file, log file and error file
	fclose(yyin);
	fclose(logFile);
	fclose(errorFile);

	return 0;
}
