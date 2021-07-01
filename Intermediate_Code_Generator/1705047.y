%{
// Created by: Jayanta Sadhu
#include<iostream>
#include<sstream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<set>
#include<regex>
#include "SymbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);

// ------------------------------------------------------------
// 	variables to count errors
// 	ERR_COUNT -> lexical errors
// 	SMNTC_ERR_COUNT -> syntactical errors
// ------------------------------------------------------------


int ERR_COUNT=0;
int SMNTC_ERR_COUNT = 0;
extern int lineCnt;

// ------------------------------------------------------------
// 	File Pointers
// ------------------------------------------------------------


extern FILE *yyin;
FILE *fp;
FILE *logFile; // log file pointer: to write in log file
FILE *codeFile;
FILE *optimized_code;
FILE *errorFile; // error file pointer: to write in error files

// label and temp counter
int LABEL_CTR = 0;
int TEMP_CTR = 0;


// ------------------------------------------------------------
// 	containers and structures
// ------------------------------------------------------------

// to store the informations of a variable
struct variableInfo {
	std::string var_name;
	std::string var_size;
};

// Necessary global string variables
// used for storing codes, errors and assembly codes
std::string code_segm; // build to store code segments to be written in log files
std::string err_segm; // build to store error segments to be written in error files
std::string assmCode; // build to store assembly codes to be written in asm file

vector<string> code_vect;

// container to store the arguments passed into a function
// arguments from argument_list are sequentially added into arg_vect
// arguments later matched with parameters of a function
vector<symbolInfo*> arg_vect;

// container to store the variables in declaration list
// variables that appear in reduction of declaration_list are
// sequentially added in var_vect
// variables are inserted into symbol table from var_vect
vector<variableInfo*> var_vect;

// container to hold parameters during declaration of function
// parameters are sequentially added into temp_param_list
vector<param*> temp_param_list;

// pointer to symbol table
// initiated in main function
SymbolTable *table;


// auxilliary variables
variableInfo *varPtr;
param *p;
std::string type, curr_func_name;
std::string name, final_name;
std::string return_type;
std::string current_return_type;
bool insideMain = false; // true if inside main function
bool is_func_valid;

vector<string> recieveArg_list;  // arguments to be recieved by a function

/* recordOnStk_list
for sending arguments to a function
keeps track of arguments symbol later used to save on stack  */

vector<string> recordOnStk_list;

// initVarSet-> set to store variable names to be declared in .code segment
set<std::string> initVarSet;
std::vector<std::pair<std::string, std::string>> initArrSet;


/*
------------------------------------------------------------
	DEFINED FUNCTION
------------------------------------------------------------
*/


void writeToLog(std::string msg, bool lineNum = true, bool doubleGap=true)
{
	// msg -> the statement to be written in log file
	// lineNum -> prints a line with line number
	// doubleGap -> if true gives two line gaps, otherwise a single gap

	if (lineNum)
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
	// msg -> the statement to be written in log file
	// writeOnAll -> if true writes on both log and error files, otherwise writes only on error file

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


std::string newLabel()
{
	std::string label = "LB";
	std::string suff;
	std::stringstream ss;
	ss<<LABEL_CTR;
	ss>>suff;
	label += suff;
	LABEL_CTR++;
	return label;
}

std::string newTemp(std::string varName)
{
	varName = "tmp" + varName;
	std::string currId = table->getCurrentScopeID();
	for(int i=0; i<currId.size(); i++)
	{
		if(currId[i] == '.') currId[i] = '_';
	}
	varName += currId;
	return varName;
}

void insertVarIntoTable(std::string varType, variableInfo *vp)
{
	symbolInfo *si = new symbolInfo(vp->var_name, "ID");

	si->setVarType(varType);
	printf("variable name: %s, type: %s\n", si->getName().c_str(), si->getVarType().c_str());
	int varSize = atoi(vp->var_size.c_str());
	//printf("Insertion func, array size = %d\n", varSize);
	si->setArrSize(varSize);
	// code for setting up symbol
	// need to assign a symbol for the variable
	string tempVar = newTemp(vp->var_name);

	if (varSize == -1)
	{
		si->setIdType("variable");
		initVarSet.insert(tempVar);
	}
	else
	{
		si->setIdType("array");
		initArrSet.push_back(make_pair(tempVar, vp->var_size));
	}


	si->setSymbol(tempVar);
	si->setCode("");

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
	if (funcName == "main") insideMain = true;
	else insideMain = false;
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
			writeError("Return type mismatch for function " + funcName);
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

std::string stripArr(std::string Name)
{
	int i;
	for(i=0; i<Name.size(); i++)
	{
		if(Name[i]=='[')break;
	}
	if (i>=Name.size())
	{
		// printf("error in array name sent to strip array function\n");
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
		writeError("Void function call within expression");
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

%token IF ELSE FOR WHILE INT FLOAT VOID RETURN
%token ASSIGNOP LPAREN RPAREN LCURL RCURL DECOP PRINTF
%token LTHIRD RTHIRD COMMA SEMICOLON NOT PRINTLN INCOP

%token<symbol>CONST_INT
%token<symbol>CONST_FLOAT
%token<symbol>ID
%token<symbol>ADDOP
%token<symbol>MULOP
%token<symbol>RELOP
%token<symbol>LOGICOP

%type<symbol>program unit func_declaration func_definition func_definition_initP func_definition_init parameter_list
%type<symbol>compound_statement var_declaration type_specifier declaration_list statements statement
%type<symbol>expression_statement variable expression logic_expression rel_expression simple_expression term
%type<symbol>unary_expression factor argument_list arguments

/* %type<symbol>error_statement error_expression */

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		//fprintf(logFile, "Line %d : start : program\n\n", lineCnt-1);// lineCnt is decreased by 1
												//because it read the last newline of input file and falsely incremented line count
		/* for (auto str : code_vect)
		{
			writeToLog(str, false);
		} */
		writeToLog($1->getName(), false);
		if (SMNTC_ERR_COUNT + ERR_COUNT == 0) // only create the assembly code if there are no errors
		{
			std::ostringstream oss;
			oss<<".MODEL SMALL"<<endl<<endl;
			oss<<".STACK 100H"<<endl<<endl;
			oss<<".DATA"<<endl;

			oss<<"\tNL EQU 0AH"<<endl;
			oss<<"\tCR EQU 0DH"<<endl;
			// variable declaration in data segment
			for(auto x: initVarSet)
			{
				oss<<"\t"<<x<<" DW ?"<<endl;
			}

			for(auto x: initArrSet)
			{
				oss<<"\t"<<x.first<<" DW "<<x.second<<" DUP<?>"<<endl;
			}

			initArrSet.clear();
			initVarSet.clear();

			oss<<"\taddress DW ?"<<endl;
			oss<<"\tprintData DW 0"<<endl;

			// code segment
			oss<<".CODE "<<endl;
			oss<<$1->getCode();

			// printing procedure code
			// the value to be printed is stored in printData variable
			oss<<"PRINTF PROC"<<endl;
			oss<<"\tPUSH AX"<<endl;
			oss<<"\tPUSH BX"<<endl;
			oss<<"\tPUSH CX"<<endl;
			oss<<"\tPUSH DX"<<endl;
			oss<<"\tXOR CX, CX"<<endl;
			oss<<"\tMOV BX, 10D"<<endl;
			oss<<"\tMOV AX, printData"<<endl;
			oss<<"\tCMP AX, 0H"<<endl;
			oss<<"\tJGE @REPEAT"<<endl;
			oss<<"\tMOV DL, '-'"<<endl;
			oss<<"\tPUSH AX"<<endl;
			oss<<"\tMOV AH, 02H"<<endl;
			oss<<"\tINT 21H"<<endl;
			oss<<"\tPOP AX"<<endl;
			oss<<"\tNEG AX"<<endl;
			oss<<"\t@REPEAT:"<<endl;
			oss<<"\tXOR DX, DX"<<endl;
			oss<<"\tDIV BX"<<endl;
			oss<<"\tPUSH DX"<<endl;
			oss<<"\tINC CX"<<endl;
			oss<<"\tOR AX, AX"<<endl;
			oss<<"\tJNE @REPEAT"<<endl;
			oss<<"\tMOV AH, 02H"<<endl;
			oss<<"\t@PRINT:"<<endl;
			oss<<"\tPOP DX"<<endl;
			oss<<"\tOR DL, 30H"<<endl;
			oss<<"\tINT 21H"<<endl;
			oss<<"\tLOOP @PRINT"<<endl;
			oss<<"\tMOV AH, 02H"<<endl;
			oss<<"\tMOV DX, NL"<<endl;
			oss<<"\tINT 21H"<<endl;
			oss<<"\tMOV DX, CR"<<endl;
			oss<<"\tINT 21H"<<endl;
			oss<<"\tPOP DX"<<endl;
			oss<<"\tPOP CX"<<endl;
			oss<<"\tPOP BX"<<endl;
			oss<<"\tPOP AX"<<endl;
			oss<<"\tRET"<<endl;
			oss<<"\tPRINTF ENDP"<<endl;

			oss<<"END MAIN"<<endl;
			assmCode = oss.str();
			//printf("%s", assmCode.c_str());
			fprintf(codeFile, "%s", assmCode.c_str());
		}
	}
	;

program : program unit
	{
		/* writeToLog("program : program unit");
		code_vect.push_back($2->getName());
		for(int i = 0; i < code_vect.size(); i++)
		{
			writeToLog(code_vect[i], false, false);
		}
		writeToLog("", false, false);
		 */
		$$ = new symbolInfo($1->getName() + $2->getName(), "program");
		$$->setCode($1->getCode() + $2->getCode());
		writeToLog($1->getName() + $2->getName(), false);
		delete $1;
		delete $2;
	}
	| unit
	{
		writeToLog("program : unit");
		writeToLog($1->getName(), false);
		$$ = $1;
		$$->setType("program");
	}
	;

unit : var_declaration
	{
		writeToLog("unit : var_declaration");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
		$$->setCode($1->getCode());
		delete $1;
	}
	| func_declaration
	{
		writeToLog("unit : func_declaration");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
		$$->setCode($1->getCode());
		delete $1;
	}
	| func_definition
	{
		writeToLog("unit : func_definition");
		writeToLog($1->getName(), false);
		$$ = new symbolInfo($1->getName(), "unit");
		$$->setCode($1->getCode());
		delete $1;
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

		delete $1;
		delete $2;
		delete $4;
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		code_segm = $1->getName() + " " + $2->getName() + "(" + ");" ;
		writeToLog("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_declaration");
		checkFunctionDec($2->getName(), $1->getName());
		temp_param_list.clear();

		delete $1;
		delete $2;
	}
	;

func_definition : func_definition_initP compound_statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_definition");
		$$->setVarType($1->getVarType());

		// assembly code for function definition

		// if the procedure/function is main, main proc has to be declared
		// and data segment initialization has to be performed
		std::ostringstream oss;
		// initVarSet.insert("address");
		if (is_func_valid)
		{
			if (curr_func_name == "main")
			{
				oss<<"MAIN PROC"<<endl;
				oss<<"\tMOV AX, @DATA"<<endl;
				oss<<"\tMOV DS, AX"<<endl;
				oss<<$2->getCode();
				// exit DOS
				oss<<endl;
				oss<<"\tMOV AH, 4CH"<<endl;
				oss<<"\tINT 21H"<<endl;
				oss<<"\tMAIN ENDP"<<endl;
			}
			else
			{
				oss<<curr_func_name<<" PROC"<<endl;
				oss<<"\tPOP address"<<endl;
				for(int i = recieveArg_list.size()-1; i>=0; i--)
				{
					oss<<"\tPOP "<<recieveArg_list[i]<<endl;
				}
				oss<<$2->getCode();
				oss<<"\t@RETURN:"<<endl;
				oss<<"\tPUSH address"<<endl;
				oss<<"\tRET"<<endl;
				oss<<curr_func_name<<" ENDP"<<endl;
			}
			is_func_valid = false;
		}
		$$->setCode(oss.str());
		recieveArg_list.clear();
		delete $1;
		delete $2;
	}
	| func_definition_init compound_statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "func_definition");
		$$->setVarType($1->getVarType());

		// assembly code for function definition

		// if the procedure/function is main, main proc has to be declared
		// and data segment initialization has to be performed
		std::ostringstream oss;
		// initVarSet.insert("address");
		if (is_func_valid)
		{
			if (curr_func_name == "main")
			{
				oss<<"MAIN PROC"<<endl;
				oss<<"\tMOV AX, @DATA"<<endl;
				oss<<"\tMOV DS, AX"<<endl;
				oss<<$2->getCode();
				// exit DOS
				oss<<endl;
				oss<<"\tMOV AH, 4CH"<<endl;
				oss<<"\tINT 21H"<<endl;
			}
			else
			{
				oss<<curr_func_name<<" PROC"<<endl;
				oss<<"\tPOP address"<<endl;
				/* for(int i = recieveArg_list.size()-1; i>=0; i--)
				{
					oss<<"\tPOP "<<recieveArg_list[i]<<endl;
				} */
				oss<<$2->getCode();
				oss<<"\tPUSH address"<<endl;
				oss<<"\tRET"<<endl;
				oss<<curr_func_name<<" ENDP"<<endl;
			}
			is_func_valid = false;
		}
		$$->setCode(oss.str());

		delete $1;
		delete $2;
	}
	;

func_definition_initP : type_specifier ID LPAREN parameter_list RPAREN
	{
		int curr_err = SMNTC_ERR_COUNT;
		checkFunctionDef($2->getName(), $1->getName());
		// checking if there is any additional error
		if (curr_err != SMNTC_ERR_COUNT) is_func_valid = false;
		else is_func_valid = true;

		code_segm = $1->getName() + " " + $2->getName() + "(" + $4->getName() + ")";
		$$ = new symbolInfo(code_segm, "func_definition_initP");
		$$->setVarType($1->getName());
		current_return_type = $1->getName();
		curr_func_name = $2->getName();

		delete $1;
		delete $2;
		delete $4;
	};

func_definition_init : type_specifier ID LPAREN RPAREN
	{
		int curr_err = SMNTC_ERR_COUNT;
		checkFunctionDef($2->getName(), $1->getName());
		// checking if there is any additional error
		if (curr_err != SMNTC_ERR_COUNT) is_func_valid = false;
		else is_func_valid = true;

		code_segm = $1->getName() + " " + $2->getName() + "()";
		$$ = new symbolInfo(code_segm, "func_definition_init");
		$$->setVarType($1->getName());
		current_return_type = $1->getName();
		curr_func_name = $2->getName();
		delete $1;
		delete $2;
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

		delete $1;
		delete $3;
		delete $4;
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

		delete $1;
		delete $3;
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
		delete $1;
		delete $2;
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
	/* | type_specifier error
	{
		printf("error reporting\n");
		yyclearin;
		yyerrok;
	} */
	;


compound_statement : LCURL interimScopeAct statements RCURL
	{
		code_segm = "{\n"+$3->getName()+"}";
		writeToLog("compound_statement : LCURL statements RCURL");
		writeToLog(code_segm, false);

		$$ = new symbolInfo(code_segm, "compound_statement");
		$$->setCode($3->getCode());
		table->printAllScopeTable();

		table->ExitScope();
		//current_return_type = "";
		delete $3;
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
				recieveArg_list.push_back(newTemp(p->param_name));
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
			for ( int i=0; i<var_vect.size(); i++)
			{
				insertVarIntoTable(varType, var_vect[i]);
			}
		}

		var_vect.clear();
		writeToLog(code_segm, false);

		delete $1;
		delete $2;
	}
	;

type_specifier : INT
	{
		writeToLog("type_specifier : INT");
		writeToLog("int", false);
		$$ = new symbolInfo("int", "INT");
	}
	| FLOAT
	{
		writeToLog("type_specifier : FLOAT");
		writeToLog("float", false);
		$$ = new symbolInfo("float", "FLOAT");
	}
	| VOID
	{
		writeToLog("type_specifier : VOID");
		writeToLog("void", false);
		$$ = new symbolInfo("void", "VOID");
	}
	;

declaration_list : declaration_list COMMA ID
	{
		code_segm = $1->getName()+", "+$3->getName();

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

		writeToLog("declaration_list : declaration_list COMMA ID");
		writeToLog(code_segm, false);

		delete $1;
		delete $3;

	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		code_segm = $1->getName()+", "+$3->getName()+"["+$5->getName()+"]";

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

		writeToLog("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
		writeToLog(code_segm, false);

		delete $1;
		delete $3;
		delete $5;

	}
	| ID
	{

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

		writeToLog("declaration_list : ID");
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

		writeToLog("declaration_list : ID LTHIRD CONST_INT RTHIRD");
		writeToLog(code_segm, false);
		delete $1;
		delete $3;

	}
	;

statements : statement
	{
		writeToLog("statements : statement");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setName($1->getName()+"\n");
		$$->setType("statements");
	}
	| statements statement
	{
		code_segm = $1->getName() + $2->getName();
		writeToLog("statements : statements statement");
		writeToLog(code_segm, false);
		$$=new symbolInfo(code_segm+"\n", "statements");
		$$->setCode($1->getCode() + $2->getCode());
		delete $1;
		delete $2;
	}
	/* | statements error_statement
	{
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		printf("Converging into statements\n");
	} */
	;

statement : var_declaration
	{
		writeToLog("statement : var_declaration");
		writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| expression_statement
	{
		writeToLog("statement : expression_statement");
		writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| compound_statement
	{
		writeToLog("statement : compound_statement");
		writeToLog($1->getName(), false);
		$$=$1; $$->setType("statement");
	}
	| func_definition
	{
		writeError("Invalid Scope Error");
		SMNTC_ERR_COUNT++;
		writeToLog("statement : func_definition");
		writeToLog($1->getName(), false);
		$$=$1; //$$->setName("");
	}
	| func_declaration
	{
		writeError("Invalid Scope Error");
		SMNTC_ERR_COUNT++;
		writeToLog("statement : func_declaration");
		writeToLog($1->getName(), false);
		$$=$1; //$$->setName("");
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

		delete $3;
		delete $4;
		delete $5;
		delete $7;
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

		// MOV AX, EXPR
		// CMP AX, 0
		// JE LABEL1
		// STATEMENT CODE
		// LABEL1:
		string label1 = newLabel();
		std::ostringstream oss;
		oss<<$3->getCode();
		oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
		oss<<"\tCMP AX, 0"<<endl;
		oss<<"\tJE "<<label1<<endl;
		oss<<$5->getCode();
		oss<<"\t"<<label1<<":"<<endl;
		$$->setCode(oss.str());

		delete $3;
		delete $5;
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

		// MOV AX, EXPR
		// CMP AX, 0
		// JE LABEL1
		// STATEMENT1 CODE
		// JMP LABEL2
		// LABEL1:
		// STATEMENT2 CODE
		// LABEL2:

		string label1 = newLabel();
		string label2 = newLabel();

		std::ostringstream oss;
		oss<<$3->getCode();
		oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
		oss<<"\tCMP AX, 0"<<endl;
		oss<<"\tJE "<<label1<<endl;
		oss<<$5->getCode();
		oss<<"\tJMP "<<label2<<endl;
		oss<<"\t"<<label1<<":"<<endl;
		oss<<$7->getCode();
		oss<<"\t"<<label2<<":"<<endl;

		$$->setCode(oss.str());
		delete $3;
		delete $5;
		delete $7;

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

		string label1 = newLabel();
		string label2 = newLabel();

		std::ostringstream oss;

		oss<<"\t"<<label1<<":"<<endl;
		oss<<$3->getCode();
		oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
		oss<<"\tCMP AX, 0"<<endl;
		oss<<"\tJE "<<label2<<endl;
		oss<<$5->getCode();
		oss<<"\tJMP "<<label1<<endl;
		oss<<label2<<":"<<endl;

		assmCode = oss.str();
		$$->setCode(assmCode);

		delete $3;
		delete $5;
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

		delete $3;
	}
	| PRINTF LPAREN ID RPAREN SEMICOLON
	{
		code_segm = "printf("+$3->getName()+")"+";";
		// writeToLog("statement : PRINTF LPAREN ID RPAREN SEMICOLON");
		bool is_valid = true;

		// check if the declared ID is declared or not
		symbolInfo *x = table->LookUpInAll($3->getName());
		if (x == nullptr)
		{
			err_segm = "Undeclared variable " + $3->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			is_valid = false;
		}
		else if (x->getIdType() != "variable")
		{
			err_segm = $3->getName() + " not a variable";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			is_valid = false;
		}
		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		writeToLog(code_segm, false);

		// after printf, a specific procedure is called for the purpose of displaying argument
		// SAVE 'ID' DATA TO PRINT VARIABLE
		// CALL PRINTLN
		if (is_valid)
		{
			string tempVar = "printData";
			/* initVarSet.insert(tempVar); */
			std::ostringstream oss;
			oss<<"\tMOV AX, "<<x->getSymbol()<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
			oss<<"\tCALL PRINTF"<<endl; // the value stored in 'printData' has to be shown
			assmCode = oss.str();
			$$->setCode(assmCode);
		}
		// delete $3;

	}
	| RETURN expression SEMICOLON
	{
		code_segm = "return "+$2->getName()+";";
		writeToLog("statement : RETURN expression SEMICOLON");

		$$ = new symbolInfo(code_segm, "statement");
		$$->setType("statement");
		bool is_valid = true;
		if (voidFuncCall($2->getVarType()))
		{
			// void function cannot be called in expression
			$2->setVarType("int"); // default type is int
			is_valid = false;
		}

		return_type = $2->getVarType();
		if ($2->getVarType() != current_return_type)
		{
			SMNTC_ERR_COUNT++;
			err_segm = "Type mismatch, return type expected: " + current_return_type
						+ " found: " + $2->getVarType();
			writeError(err_segm);
			$2->setVarType(current_return_type);
			// is_valid = false;
		}
		else if (voidFuncCall($2->getVarType()))
		{
			/* void function cannot be called in expression */
			$2->setVarType("int"); // default type is int
		}
		writeToLog(code_segm, false);

		if(is_valid)
		{
			$$->setCode($2->getCode() + "\tPUSH " + $2->getSymbol() + "\n"+
			"\tJMP @RETURN\n");
			// return statement would be given in procedure
		}
		delete $2;
	}
	;

/* error_statement : error_expression
	{
		// printf("error_statement : error_expression\n");
		$$ = $1;
	}; */

expression_statement : SEMICOLON
	{
		writeToLog("expression_statement : SEMICOLON");
		writeToLog(";", false);
		$$ = new symbolInfo(";", "expression_statement");
		$$->setSymbol(";"); // used in for loop
	}
	| expression SEMICOLON
	{
		code_segm = $1->getName() + ";";
		writeToLog("expression_statement : expression SEMICOLON");

		// commented out because of input4 mismatch
		/* if (voidFuncCall($1->getVarType()))
		{
			// void function cannot be called in expression
			$1->setVarType("int");
		} */
		$$ = new symbolInfo(code_segm, "expression_statement");
		$$->setVarType($1->getVarType());
		writeToLog(code_segm, false);
		$$->setSymbol($1->getSymbol());
		$$->setCode($1->getCode());
		delete $1;

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
			$$->setSymbol(x->getSymbol());
			$$->setCode(x->getCode());
		}
		else
		{
			err_segm = "Undeclared variable " + $$->getName();
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			$$->setVarType("undec"); // assign the default type int
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

		$$ = new symbolInfo(code_segm, "variable");
		$$->setIdType("array");

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
			$$->setArrSize(0);
			$$->setVarType("undec");
		}
		else if (sts->getIdType() != "array" || sts->getArrSize() == -1) // checking if array or not
		{
			err_segm = "Type mismatch, " + sts->getName() + " is not an array";
			writeError(err_segm);
			SMNTC_ERR_COUNT++;
			$$->setArrSize(0);
			$$->setVarType("int");
		}
		else
		{
			$$->setVarType(sts->getVarType());
			int index = ($3->getVarType()=="int")?atoi($3->getName().c_str()):0;
			if (index>=sts->getArrSize() && $3->getVarType()=="int")
			{
				SMNTC_ERR_COUNT++;
				writeError("Array index out of bound");
			}
			else $$->arrIndex = index;
			$$->setArrSize(sts->getArrSize());
			$$->setSymbol(sts->getSymbol());
		}
		$$->setCode($3->getCode() + "\tMOV BX, " + $3->getSymbol()+"\n\t" +
					"ADD BX,BX\n");
		writeToLog(code_segm, false);

		delete $1;
		delete $3;
	}
	;


 expression : logic_expression
	{
		writeToLog("expression : logic_expression");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("expression");
	}
	| variable ASSIGNOP logic_expression
	{
		code_segm = $1->getName() + "=" + $3->getName();
		writeToLog("expression : variable ASSIGNOP logic_expression");

		$$ = new symbolInfo(code_segm, "expression");
		$$->setVarType($1->getVarType());
		bool is_valid = true;

		// checking if the operands on both sides have same type
		// or if left operand has higher precedence than operand on right
		if ($1->getVarType() != $3->getVarType()) {
			if (!($1->getVarType() == "float" && $3->getVarType() != "void"))
			{
				//printf("%s type=%s, %s type=%s\n",$1->getName().c_str(), $1->getVarType().c_str(), $3->getName().c_str(), $3->getVarType().c_str());
				writeError("Type mismatch");
				SMNTC_ERR_COUNT++;
				is_valid = false;
			}
		}

		if (voidFuncCall($3->getVarType()))
		{
			/* void function cannot be called in expression */
			$3->setVarType("int"); is_valid = false;
		}

		writeToLog(code_segm, false);
		if (is_valid)
		{
			std::ostringstream oss;
			string tempVar = newTemp("expr");

			oss<<$3->getCode()<<$1->getCode();
			if ($3->getIdType() == "array" || $3->getArrSize() >=0)
			{
				oss<<"\tMOV AX, "<<$3->getSymbol()<<"[BX]"<<endl;
			}
			else
			{
				oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
			}

			if ($1->getIdType() == "array"|| $1->getArrSize() >=0)
			{
				initVarSet.insert(tempVar);
				oss<<"\tMOV "<<$1->getSymbol()<<"[BX], AX"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				$$->setSymbol(tempVar);
			}
			else
			{
				oss<<"\tMOV "<<$1->getSymbol()<<", AX"<<endl;
				$$->setSymbol($1->getSymbol());
			}
			$$->setCode(oss.str());
		}

		delete $1;
		delete $3;
	}
	;


logic_expression : rel_expression
	{
		writeToLog("logic_expression : rel_expression");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("logic_expression");
	}
	| rel_expression LOGICOP rel_expression
	{
		code_segm = $1->getName() + $2->getName() + $3->getName();
		writeToLog("logic_expression : rel_expression LOGICOP rel_expression");

		$$ = new symbolInfo(code_segm, "logic_expression");
		$$->setVarType("int");

		bool is_valid = true;
		/* void function cannot be called in expression */
		if (voidFuncCall($1->getVarType()) || voidFuncCall($3->getVarType())) {is_valid = false;}
		writeToLog(code_segm, false);
		if ($1->getVarType() != "int" || $3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			writeError("Non-Integer operand in relational operator");
			is_valid = false;
		}

		if (is_valid)
		{
			string tempVar = newTemp("logic_expr");
			initVarSet.insert(tempVar);
			std::ostringstream oss;
			oss<<$1->getCode()<<$3->getCode();
			string label1 = newLabel();
			string label2 = newLabel();
			// && OPERATION
			// MOV AX, REL_EXPR1
			// CMP AX, 0
			// JE LABEL1
			// MOV AX, REL_EXPR2
			// CMP AX, 0
			// JE LABEL1
			// MOV AX, 1
			// MOV TEMPVAR, AX
			// JMP LABEL2
			// LABEL1:
			// MOV AX, 0
			// MOV TEMPVAR, AX
			// LABEL2:

			// || OPERATION
			// MOV AX, REL_EXPR1
			// CMP AX, 1
			// JE LABEL1
			// MOV AX, REL_EXPR2
			// CMP AX, 1
			// JE LABEL1
			// MOV AX, 0
			// MOV TEMPVAR, AX
			// JMP LABEL2
			// LABEL1:
			// MOV AX, 1
			// MOV TEMPVAR, AX
			// LABEL2:

			if($2->getName() == "&&")
			{
				oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
				oss<<"\tCMP AX, 0"<<endl;
				oss<<"\tJE "<<label1<<endl;
				oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
				oss<<"\tCMP AX, 0"<<endl;
				oss<<"\tJE "<<label1<<endl;
				oss<<"\tMOV AX, 1"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				oss<<"\tJMP "<<label2<<endl;
				oss<<"\t"<<label1<<":"<<endl;
				oss<<"\tMOV AX, 0"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				oss<<"\t"<<label2<<":"<<endl;
			}
			else
			{
				oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
				oss<<"\tCMP AX, 1"<<endl;
				oss<<"\tJE "<<label1<<endl;
				oss<<"\tMOV AX, "<<$3->getSymbol()<<endl;
				oss<<"\tCMP AX, 1"<<endl;
				oss<<"\tJE "<<label1<<endl;
				oss<<"\tMOV AX, 0"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				oss<<"\tJMP "<<label2<<endl;
				oss<<"\t"<<label1<<":"<<endl;
				oss<<"\tMOV AX, 1"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				oss<<"\t"<<label2<<":"<<endl;
			}
			assmCode = oss.str();
			$$->setCode(assmCode);
			$$->setSymbol(tempVar);
		}

		delete $1;
		delete $2;
		delete $3;
	}
	;


rel_expression	: simple_expression
	{
		writeToLog("rel_expression : simple_expression");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("rel_expression");
	}
	| simple_expression RELOP simple_expression
	{
		code_segm = $1->getName()+$2->getName()+$3->getName();
		writeToLog("rel_expression : simple_expression RELOP simple_expression");

		$$ = new symbolInfo(code_segm, "rel_expression");
		$$->setVarType("int");
		bool is_valid = true;

		/* void function cannot be called in expression */
		if (voidFuncCall($1->getVarType()) || voidFuncCall($3->getVarType()))
		{ is_valid = false; }

		writeToLog(code_segm, false);

		if (is_valid)
		{
			// RELOP includes <. <=, >, >=, ==
			string tempVar = newTemp("rel_expr");
			std::ostringstream oss;
			initVarSet.insert(tempVar);
			// add the previous code to string stream
			oss<<$1->getCode()<<$3->getCode();

			// MOV AX, SMPL_EXPR
			// CMP AX, SMPL_EXPR2

			oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
			oss<<"\tCMP AX, "<<$3->getSymbol()<<endl;
			string label1 = newLabel();
			string label2 = newLabel();

			string relopSign = $2->getName();
			// JL LABEL1
			// MOV AX, 0
			// JMP LABEL2
			// LABEL1:
			// MOV AX, 1
			// LABEL2:
			if(relopSign == "<")
			{
				oss<<"\tJL "<<label1<<endl;

			}
			else if (relopSign == "<=")
			{
				oss<<"\tJLE "<<label1<<endl;
			}
			else if (relopSign == ">")
			{
				oss<<"\tJG "<<label1<<endl;
			}
			else if (relopSign == ">=")
			{
				oss<<"\tJGE "<<label1<<endl;
			}
			else if (relopSign == "==")
			{
				oss<<"\tJE "<<label1<<endl;
			}
			else
			{
				oss<<"\tJNE "<<label1<<endl;
			}
			oss<<"\tMOV AX, 0"<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
			oss<<"\tJMP "<<label2<<endl;
			oss<<"\t"<<label1<<":"<<endl;
			oss<<"\tMOV AX, 1"<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
			oss<<"\t"<<label2<<":"<<endl;

			assmCode = oss.str();
			$$->setCode(assmCode);
			$$->setSymbol(tempVar);
		}

		delete $1;
		delete $2;
		delete $3;
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
		$$->setVarType("int"); // default type
		bool is_valid = true;

		/* void function cannot be called in expression */
		if (voidFuncCall($1->getVarType()) ||
			voidFuncCall($3->getVarType()))
		{ is_valid = false;}

		if ($1->getVarType() == "float" || $3->getVarType() == "float")
		{
			$$->setVarType("float");
		}
		writeToLog(code_segm, false);

		// ADDOP includes +/-
		string tempVar = newTemp("simple_expr");
		initVarSet.insert(tempVar);
		std::stringstream oss;
		oss<<$1->getCode()<<$3->getCode();
		// addition or subtraction
		// MOV AX, SIMPLE_EXPR
		// ADD AX, term ;OR SUB AX, term
		// MOV TEMPVAR, AX
		oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
		if ($2->getName() == "+")
		{
			oss<<"\tADD AX, "<<$3->getSymbol()<<endl;
		}
		else
		{
			oss<<"\tSUB AX, "<<$3->getSymbol()<<endl;
		}
		oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		assmCode = oss.str();
		$$->setSymbol(tempVar);
		$$->setCode(assmCode);

		delete $1;
		delete $2;
		delete $3;
	}
	;

term :	unary_expression
	{
		writeToLog("term : unary_expression");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setType("term");
	}
	|  term MULOP unary_expression
	{
		code_segm = $1->getName() + $2->getName() + $3->getName();
		writeToLog("term : term MULOP unary_expression");

		$$ = new symbolInfo(code_segm, "term");
		$$->setVarType("int");
		bool is_valid = true;

		/* void function cannot be called in expression */
		if (voidFuncCall($1->getVarType()) || voidFuncCall($3->getVarType()))
		{
			is_valid = false;
		}

		// checking for MULOP(%) mismatch
		if ($2->getName() == "%")
		{
			if ($1->getVarType() != "int" || $3->getVarType() != "int")
			{
				SMNTC_ERR_COUNT++;
				writeError("Non-Integer operand on modulus operator");
				is_valid = false;
			}
			if ($3->getName() == "0")
			{
				SMNTC_ERR_COUNT++;
				writeError("Modulus by Zero");
				is_valid = false;
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

		// MULOP can be *, /, %
		if (is_valid)
		{
			string tempVar = newTemp("term");
			initVarSet.insert(tempVar);
			std::ostringstream oss;
			oss<<$1->getCode()<<$3->getCode();
			if ($2->getName() == "*")
			{
				// for multiplication
				// MOV AX, TERM
				// MOV BX, UN_EXP
				// IMUL BX ; STORE THE PRODUCT OF AX, BX INTO AX
				// MOV TEMPVAR, AX
				oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
				oss<<"\tMOV BX, "<<$3->getSymbol()<<endl;
				oss<<"\tIMUL BX"<<endl;
				oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				assmCode = oss.str();
			}
			else
			{
				// for division or modulus
				// MOV AX, TERM
				// CWD ; PREPARING DX TO BE THE SIGN EXTENSION OF AX
				// MOV BX, UN_EXP
				// IDIV BX ; AX GETS QUOTIENT, DX GETS REMAINDER
				oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
				oss<<"\tCWD"<<endl;
				oss<<"\tMOV BX, "<<$3->getSymbol()<<endl;
				oss<<"\tIDIV BX"<<endl;
				// if division pass on the quotient
				// else if mod pass the remainder
				if ($2->getName() == "/")
				{
					oss<<"\tMOV "<<tempVar<<", AX"<<endl;
				}
				else
				{
					oss<<"\tMOV "<<tempVar<<", DX"<<endl;
				}

			}
			assmCode = oss.str();
			$$->setCode(assmCode);
			$$->setSymbol(tempVar);
		}

		writeToLog(code_segm, false);

		delete $1;
		delete $2;
		delete $3;
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

		// ADDOP can be +/-
		// if negative, the value of unary_expression has to be made negative
		// otherwise nothing has to be done
		std::ostringstream oss;
		std::string tempVar = newTemp("un_expr");
		initVarSet.insert(tempVar);
		if ($1->getName() == "-")
		{
			oss<<$2->getCode();
			oss<<"\tMOV AX, "<<$2->getSymbol()<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
			oss<<"\tNEG "<<tempVar<<endl;
			assmCode = oss.str();
			$$->setSymbol(tempVar);
			$$->setCode(assmCode);
		}
		else
		{
			$$->setSymbol($2->getSymbol());
			$$->setCode($2->getCode());
		}

		delete $1;
		delete $2;

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

		// NOT is ! ; if value greater than 0, it is made 1 and nonzero num is made 0
		std::ostringstream oss;
		std::string tempVar = newTemp("un_expr");
		initVarSet.insert(tempVar);
		string label1 = newLabel();
		string label2 = newLabel();
		oss<<$2->getCode();
		oss<<"\tMOV AX, "<<$2->getSymbol()<<endl;
		oss<<"\tCMP AX, 0"<<endl;
		oss<<"\tJE "<<label1<<endl;
		oss<<"\tMOV AX, 0"<<endl;
		oss<<"\tJMP "<<label2<<endl;
		oss<<"\t"<<label1<<": "<<endl;
		oss<<"\tMOV AX, 1"<<endl;
		oss<<"\t"<<label2<<":"<<endl;
		oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		// MOV AX, UNARY_EXP_SYMBOL
		// CMP AX, 0
		// JE LABEL1
		// MOV AX, 0
		// JMP LABEL2
		// LABEL1:
		// MOV AX, 1
		// LABEL2:
		// MOV SYM, AX

		assmCode = oss.str();
		$$->setCode(assmCode);
		$$->setSymbol(tempVar);

		delete $2;
	}
	| factor
	{
		writeToLog("unary_expression : factor");
		writeToLog($1->getName(), false);
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
		printf("check arg_vect , size = %d\n", arg_vect.size());
		for(int i = 0; i<arg_vect.size();i++)
		{
			printf("name=%s, type=%s\n", arg_vect[i]->getName().c_str(),arg_vect[i]->getVarType().c_str());
		}
		code_segm = $1->getName() + "(" + $3->getName() + ")";
		writeToLog("factor : ID LPAREN argument_list RPAREN");

		$$ = new symbolInfo(code_segm, "factor");
		/* looking up in symbol table to find if this function already exists or not */
		symbolInfo *x = table->LookUpInAll($1->getName());
		bool valid_call = true;

		/* Check if the function name exists*/
		if (x == nullptr) {
			err_segm = "Undeclared/undefined function name " + $1->getName();
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
			valid_call = false;
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
				err_segm = "Parameter and argument size does not match for function " + x->getName();
				writeError(err_segm);
				SMNTC_ERR_COUNT++;
				$$->setVarType("int");
				valid_call = false;
			}
			else
			{
				// check every parameter type
				int i;
				printf("arg_vect size = %d\n", arg_vect.size());
				for(i = 0; i<arg_vect.size();i++)
				{
					printf("name=%s, type=%s\n", arg_vect[i]->getName().c_str(),arg_vect[i]->getVarType().c_str());
				}
				for(i = 0; i<arg_vect.size();i++)
				{
					printf("arg type-> %s\n", arg_vect[i]->getVarType().c_str());
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
						valid_call = false;
						break;
					}
				}

				$$->setVarType(x->getVarType());
			}

		}

		if (x!=nullptr && x->hasFuncPtr())
		{
			if (x->funcDeclNotDef() && insideMain)
			{
				err_segm = "Function declared but not defined";
				writeError(err_segm);
				SMNTC_ERR_COUNT++;
			}
		}

		writeToLog(code_segm, false);

		// building up assembly code for function call
		if (valid_call)
		{
			std::string tempVar = newTemp("factor");
			initVarSet.insert(tempVar);
			std::ostringstream oss;
			oss<<$3->getCode();
			oss<<"\tPUSH AX"<<endl<<"\tPUSH BX"<<endl;

			if (!insideMain) {
				oss<<"\tPUSH address"<<endl;
			}
			for(auto str:recordOnStk_list)
			{
				oss<<"\tPUSH "<<str<<endl;
			}
			// calling the function
			oss<<"\tCALL "<<x->getName()<<endl;

			// returning from function call
			if (x->getFunctionInfo() != nullptr)
			{
				if (x->getFunctionInfo()->returnType != "void")
				{
					// if return type is not void, save that to a variable from stack
					oss<<"\tPOP "<<tempVar<<endl;
				}
			}

			if (!insideMain) {
				oss<<"\tPOP address"<<endl;
			}

			// releasing the registers
			oss<<"\tPOP BX"<<endl<<"\tPOP AX"<<endl;
			assmCode = oss.str();
			oss.str("");
			$$->setCode(assmCode);
			$$->setSymbol(tempVar);
		}

		arg_vect.clear(); // clearing current argument vector
		recordOnStk_list.clear(); // clearing values to be saved on stack

		delete $1;
		delete $3;
	}
	| LPAREN expression RPAREN
	{
		code_segm = "(" + $2->getName() + ")";
		writeToLog("factor : LPAREN expression RPAREN");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($2->getVarType());
		$$->setSymbol($2->getSymbol());
		$$->setCode($2->getCode());
		delete $2;
	}
	| CONST_INT
	{
		writeToLog("factor : CONST_INT");
		writeToLog($1->getName(), false);
		$$=$1;
		$$->setSymbol($$->getName()); // constant name is used as symbol in assembly code, eg "6"/ "7"
		$$->setVarType("int");

	}
	| CONST_FLOAT
	{
		// dont know what to do using float
		//writeToLog("factor : CONST_FLOAT");
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
		$$->setSymbol($$->getName());
		writeToLog(val, false);

	}
	| variable INCOP
	{
		code_segm = $1->getName() + "++";
		writeToLog("factor : variable INCOP");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($1->getVarType()); /* type setting */

		// temporary variable to hold factor data
		std::string tempVar = newTemp("factor");
		initVarSet.insert(tempVar);
		std::ostringstream oss;
		if($1->getIdType() == "array")
		{
			oss<<$1->getCode();
			oss<<"\tINC "<<$1->getSymbol()<<"[BX]"<<endl;
			oss<<"\tMOV AX, "<<$1->getSymbol()<<"[BX]"<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		}
		else
		{
			// variable not array
			oss<<$1->getCode();
			oss<<"\tINC "<<$1->getSymbol()<<endl;
			oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		}
		assmCode = oss.str();
		$$->setCode(assmCode);
		$$->setSymbol(tempVar);
		delete $1;
	}
	| variable DECOP
	{
		code_segm = $1->getName() + "--";
		writeToLog("factor : variable DECOP");
		writeToLog(code_segm, false);
		$$ = new symbolInfo(code_segm, "factor");
		$$->setVarType($1->getVarType()); /* type setting */

		// temporary variable to hold factor data
		std::string tempVar = newTemp("factor");
		initVarSet.insert(tempVar);
		std::ostringstream oss;
		if($1->getIdType() == "array")
		{
			oss<<$1->getCode();
			oss<<"\tDEC "<<$1->getSymbol()<<"[BX]"<<endl;
			oss<<"\tMOV AX, "<<$1->getSymbol()<<"[BX]"<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		}
		else
		{
			oss<<$1->getCode();
			oss<<"\tINC "<<$1->getSymbol()<<endl;
			oss<<"\tMOV AX, "<<$1->getSymbol()<<endl;
			oss<<"\tMOV "<<tempVar<<", AX"<<endl;
		}
		assmCode = oss.str();
		$$->setCode(assmCode);
		$$->setSymbol(tempVar);

		delete $1;
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
		printf("entering arg:- %s,  type->%s\n", $3->getName().c_str(), $3->getVarType().c_str());
		arg_vect.push_back($3); // arg_vect used to keep track of arguments
		//printf("arg_vect-> %s", arg_vect[1]->getVarType().c_str());
		// carry code forward
		$$->setCode($1->getCode() + $3->getCode());

		// save arguments to be saved on stack
		recordOnStk_list.push_back($3->getSymbol());

		delete $1;
		/* delete $3; */
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
		// carry code forward
		$$->setCode($1->getCode());

		arg_vect.push_back($1); // arg_vect used to keep track of arguments
		printf("entering arg:- %s,  type->%s\n", $1->getName().c_str(), $1->getVarType().c_str());
		recordOnStk_list.push_back($1->getSymbol()); // temp_list
		/* delete $1; */
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
	codeFile = fopen(argv[3], "w");
	errorFile = fopen(argv[4],"w");
	// checking if logfile and error files are properly working
	if (logFile == nullptr)
	{
		printf("Log File not properly opened\nTerminating program...\n");
		fclose(logFile);
		exit(1);
	}

	if (codeFile == nullptr)
	{
		printf("Code File not properly opened\nTerminating program...\n");
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
	table = new SymbolTable(6); // symbol table pointer assigned to table
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
	fclose(codeFile);
	fclose(errorFile);

	return 0;
}
