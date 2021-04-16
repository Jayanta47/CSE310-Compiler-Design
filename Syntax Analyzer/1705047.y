%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include "1705047_SymbolTable.h"
//#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);

int ERR_COUNT;
int SMNTC_ERR_COUNT = 0;
extern int lineCnt;

extern FILE *yyin;
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
	si->setArrSize(varSize);
	if (varSize == -1) {si->setIDType("variable");}
	else si->setIDType("array");
	table->Insert(si);
}

void insertFuncIntoTable(std::string name, functionInfo* funcPtr)
{
	symbolInfo *si = new symbolInfo(name, "ID");
	si->setIDType("function");
	si->setVarType(funcPtr->returnType);
	// unfinished
}


void yyerror(char *s)
{
	//write your code
	ERR_COUNT++;
	fprintf(errorFile, "Error at Line %d: %s\n\n", lineCnt, s);
}


%}

%union {
	symbolInfo *symbol;
}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHID COMMA SEMICOLON NOT PRINTLN INCOP DECOP
%token<symbol>CONST_INT
%token<symbol>CONST_FLOAT
%token<symbol>CONST_CHAR
%token<symbol>ID
%token<symbol>ADDOP
%token<symbol>MULOP
%token<symbol>RELOP
%token<symbol>LOGICOP
%token<symbol>STRING

%type<symbol>unit func_declaration func_definition parameter_list compound_statement var_declaration
%type<symbol>type_specifier declaration_list statements statement expression_statement variable
%type<symbol>expression logic_expression rel_expression simple_expression term unary_expression
%type<symbol>factor argument_list arguments


%left 
%right

%nonassoc 


%%

start : program
	{
		//write your code in this block in all the similar blocks below
		fprintf(logFile, "At line no : %d start : program\n\n", lineCnt);
		for (auto str : code_vect)
		{
			fprintf(logFile, "%s\n", str.c_str());
		}
		fprintf(logFile, "\n");
	}
	;

program : program unit 
	{
		fprintf(logFile, "At line no : %d program : program unit\n\n", lineCnt);
		code_vect.push_back($2->getName());
		for(int i = 0; i < code_vect.size(); i++)
		{
			fprintf(logFile, "%s\n", code_vect[i].c_str());
		}
		fprintf(logFile, "\n");
	}
	| unit
	{
		fprintf(logFile, "At line no : %d program : unit\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName());
		code_vect.push_back($1->getName());
	}
	;
	
unit : var_declaration
	{
		fprintf(logFile, "At line no : %d unit : var_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getname(), "unit");
		$$ = si;
	}
	| func_declaration
	{
		fprintf(logFile, "At line no : %d unit : func_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getname(), "unit");
		$$ = si;
	}
	| func_definition
	{
		fprintf(logFile, "At line no : %d unit : func_definition\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getname(), "unit");
		$$ = si;
	}
	;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no : %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", lineCnt);
		symbolInfo *s = table.Lookup($2->getName());
		if (s) 
		{
			fprintf(logFile, "Line no %d : Redeclaration of function name\n\n");
			SMNTC_ERR_COUNT++;
		}
		else 
		{
			symbolInfo *si = new symbolInfo($2->getName(), "ID");
			functionInfo *funcPtr = new functionInfo;
			funcPtr->returnType = $1->getType();
			si->setIDType("function_declaration");
		}
	}
	| type_specifier ID LPAREN RPAREN SEMICOLON
	{
		// to be done
	}
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
	| type_specifier ID LPAREN RPAREN compound_statement
	;				


parameter_list  : parameter_list COMMA type_specifier ID
	{
		fprintf(logFile, "At line no %d : parameter_list  : parameter_list COMMA type_specifier ID\n\n", lineCnt);
		code_segm = $1->getName() + " , " + $3->getName() + " " + $4->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		p = new param;
		p->param_type = $3->getName();
		p->param_name = $4->getName();
		temp_param_list.push_back(p);
	}
	| parameter_list COMMA type_specifier
	{
		fprintf(logFile, "At line no %d : parameter_list  : parameter_list COMMA type_specifier\n\n", lineCnt);
		code_segm = $1->getName() + " , " + $3->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		p = new param;
		p->param_type = $3->getName();
		p->param_name = "";
		temp_param_list.push_back(p);
	}
	| type_specifier ID
	{
		fprintf(logFile, "At line no %d : parameter_list  : type_specifier ID\n\n", lineCnt);
		code_segm = $1->getName() + " " + $2->getName();
		fprintf(logFile, "%s\n\n", code_segm.c_str());
		symbolInfo *si = new symbolInfo(code_segm, "parameter_list");
		p = new param;
		p->param_type = $1->getName();
		p->param_name = $2->getName();
		temp_param_list.push_back(p);
	}
	| type_specifier
	{
		fprintf(logFile, "At line no %d : parameter_list  : type_specifier\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1; $$->setType("parameter_list");
		p = new param;
		p->param_type = $1->getName();
		p->param_name = "";
		temp_param_list.push_back(p);
	}
	;

 		
compound_statement : LCURL interimScopeAct statements RCURL
	{
		fprintf(logFile, "At line no %d : compound_statement : LCURL statements RCURL\n\n", lineCnt);
		code_segm = "{\n"+$3->getName()+"}";
		fprintf(logFile, "%s\n\n", code.c_str());
		symbolInfo *si = new symbolInfo(code, "compound_statement");
		$$=si;
		table->printAllScopeTable();
		table->ExitScope();

	}
	| LCURL interimScope RCURL
	{
		fprintf(logFile, "At line no %d : compound_statement : LCURL RCURL\n\n", lineCnt);
		code_segm = "{\n}";
		fprintf(logFile, "%s\n\n", code.c_str());
		symbolInfo *si = new symbolInfo(code, "compound_statement");
		$$=si;
		table->printAllScopeTable();
		table->ExitScope();
	}
	;

interimScopeAct : 
	{
		table->EnterScope();
		// add parameters here
	}
	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
	{
		fprintf(logFile, "At line no %d : var_declaration : type_specifier declaration_list SEMICOLON\n\n", lineCnt);
		fprintf(logFile, "%s %s;\n\n", $1->getName().c_str(), $2->getName().c_str());
		symbolInfo *si =  new symbolInfo($1->getName()+" "+$2->getName()+";", "var_declaration");
		$$=si;
		std::string varType = $1->getName();
		if ($1->getType() == "VOID") 
		{
			fprintf(errorFile, "Line no %d : Multiple declaration of variable\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			varType = "int"; // default var type int
		}
		for ( int i=0; i<var_vect.size(); i++) 
		{
			insertVarIntoTable(varType, var_vect[i]);
		} 
		var_vect.clear();
	}
	;
 		 
type_specifier : INT
	{
		fprintf(logFile, "At line no : %d type_specifier : INT\n\n", lineCnt);
		fprintf(logFile, "int\n\n"); 
		symbolInfo *type = new symbolInfo("int", "INT");
		$$ = type;
	}
	| FLOAT
	{
		fprintf(logFile, "At line no : %d type_specifier : FLOAT\n\n", lineCnt);
		fprintf(logFile, "float\n\n");
		symbolInfo *type = new symbolInfo("float", "FLOAT");
		$$ = type;
	}
	| VOID
	{
		fprintf(logFile, "At line no : %d type_specifier : VOID\n\n", lineCnt);
		fprintf(logFile, "void\n\n");
		symbolInfo *type = new symbolInfo("void", "VOID");
		$$ = type;
	}
	;
 		
declaration_list : declaration_list COMMA ID
	{
		fprintf(logFile, "At line no : %d declaration_list : declaration_list COMMA ID\n\n", lineCnt);
		fprintf(logFile, "%s , %s\n\n", $1->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+","+$3->getName(), "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = "-1"; // -1 for variable only;

		var_vect.push_back(varPtr);
		$$=si;
		if (table->LookUp($3->getName()) == nullptr)
		{
			fprintf(errorFile, "Line no %d : Multiple declaration of variable\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		/* declaration of array */
		fprintf(logFile, "At line no : %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s , %s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str(), $5->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+","+$3->getName()+"["+$5->getName()+"]", "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $3->getName();
		varPtr->var_size = $5->getName(); // size for array variable
		var_vect.push_back(varPtr); 
		$$=si;
		if (table->LookUp($3->getName()) == nullptr)
		{
			fprintf(errorFile, "Line no %d : Multiple declaration of variable\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
	}
	| ID
	{
		fprintf(logFile, "At line no : %d declaration_list : ID\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = "-1"; // -1 for variable only;

		var_vect.push_back(varPtr);
		$$=si;
		if (table->LookUp($1->getName()) == nullptr)
		{
			fprintf(errorFile, "Line no %d : Multiple declaration of variable\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
	}
	| ID LTHIRD CONST_INT RTHIRD
	{
		/* declaration of array */
		fprintf(logFile, "At line no : %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+"["+$5->getName()+"]", "declaration_list");

		varPtr = new variableInfo;
		varPtr->var_name = $1->getName();
		varPtr->var_size = $3->getName(); // size for array variable
		var_vect.push_back(varPtr); 
		$$=si;
		if (table->LookUp($1->getName()) == nullptr)
		{
			fprintf(errorFile, "Line no %d : Multiple declaration of variable\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
	}
	;
 		  
statements : statement
	{
		fprintf(logFile, "At line no : %d statements : statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setName($1->getName()+"\n");
		$$->setType("statements");
	}
	| statements statement
	{
		fprintf(logFile, "At line no : %d statements : statement\n\n", lineCnt);
		fprintf(logFile, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str());
		$$=new symbolInfo($1->getName() + $2->getName()+"\n", "statements"); // needs further checking 
	}
	;
	   
statement : var_declaration
	{
		fprintf(logFile, "At line no : %d statement : var_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1; $$->setType("statement");
	}
	| expression_statement
	{
		fprintf(logFile, "At line no : %d statement : expression_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;$$->setType("statement");
	}
	| compound_statement
	{
		fprintf(logFile, "At line no : %d statement : compound_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;$$->setType("statement");
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "for("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;$$->setType("statement");
	}
	| IF LPAREN expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : IF LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;$$->setType("statement");
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		fprintf(logFile, "At line no : %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getname()+"else"+$7->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| WHILE LPAREN expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : WHILE LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "while("+$3->getName()+")"+$5->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineCnt);
		std::string statementC = "println("+$3->getName()+")"+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");
	}
	| RETURN expression SEMICOLON
	{
		fprintf(logFile, "At line no : %d statement : RETURN expression SEMICOLON\n\n", lineCnt);
		std::string statementC = "return "+$2->getName()+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si; $$->setType("statement");

		if ($2->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

		return_type = $2->getVarType();
	}
	;
	  
expression_statement : SEMICOLON			
	{
		fprintf(logFile, "At line no : %d expression_statement : SEMICOLON\n\n", lineCnt);
		fprintf(logFile, ";\n\n");

		symbolInfo *si = new symbolInfo(";", "expression_statement");
		$$ = si;
		//type = "int";
	}
	| expression SEMICOLON
	{
		fprintf(logFile, "At line no : %d expression_statement : expression SEMICOLON\n\n");
		fprintf(logFile, "%s;\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName() + ";", "expression_statement");
		si->setVarType($1->getVarType());
		$$=si;
		//type = "int";
	} 
	;
	  
variable : ID 		
	{
		fprintf(logFile, "At line no : %d variable : ID\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());

		$$ = $1;
		$$->setIDType("variable");
		// check if this variable already exists in symbol table
		symbolInfo *x = table->LookUp($$->getName());
		if (x) 
		{
			$$->setVarType(x->getVarType()); // variable declaration is okay
		}
		else 
		{
			fprintf(errorFile, "Line no %d : undeclared variable\n\n". lineCnt);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}

		if (x != nullptr && x->getArrSize()!=-1)
		{
			fprintf(errorFile, "Line no %d : type mismatch for variable\n\n". lineCnt);
			SMNTC_ERR_COUNT++;
		}
	}
	 | ID LTHIRD expression RTHIRD 
	{
		fprintf(logFile, "At line no : %d variable : ID LTHIRD expression RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str());

		//check if expression(index) is int
		if ($3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			fprintf(errorFile, "Line no %d : Invalid datatype for index\n\n");
		}

		// check if expression is calling void function
		if ($3->getVarType() == "void")
		{
			/* function cannot be called in expression */
			fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}

		symbolInfo *si = new symbolInfo(
			$1->getName() + "[" + $3->getName() + "]",
			"variable"
		);
		
		si->setIDType("array");
		symbolInfo *sts = table->LookUp($1->getName());
		if (sts == nullptr) {
			fprintf(errorFile, "Line no %d : Variable not declared\n\n");
			SMNTC_ERR_COUNT++;
			si->setVarType("int");
		}
		else if (sts->getIdType() != "array" || sts->getArrSize() == -1) // checking if array or not
		{
			fprintf(errorFile, "Line no %d : type mismatch(not array)\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
		}
		else 
		{
			si->setVarType(sts->getVarType());
			int index = atoi($3->getName().c_str());
			if (index>=si->getArrSize())
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Array index out of bound\n\n");
			}
			else si->arrIndex = index;
			si->setArrSize(sts->getArrSize());
		}
		$$=si;

	}
	;
	 
 expression : logic_expression	
		{
			fprintf(logFile, "At line no : %d expression : logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("expression");
		}
	   | variable ASSIGNOP logic_expression
	   {
		   	fprintf(logFile, "At line no : %d expression : variable ASSIGNOP logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s = %s\n\n", $1->getName().c_str(), $3->getName().c_str());
			if ($3->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$3->setType("int");
			}
			if ($1->getVarType() != $3->getVarType()) {
				fprintf(errorFile, "Line no %d : type mismatch in assignment\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}


			$$ = new symbolInfo($1->getName() + "=" + $3->getName(), "expression");
			symbolInfo *x = table->Lookup($1->getName());
			if (x==nullptr) {
				fprintf(errorFile, "Line no %d : Variable not declared in this scope\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$$->setVarType("int");
			}
			else {
				$$->setVarType(x->getVarType());
			}
			type = $1->getVarType();
	   } 	
	   ;
			
logic_expression : rel_expression 	
		{
			fprintf(logFile, "At line no : %d logic_expression : rel_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("logic_expression");
		}
		| rel_expression LOGICOP rel_expression 	
		{
			fprintf(logFile, "At line no : %d logic_expression : rel_expression LOGICOP rel_expression\n\n");
			fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
					$2->getName().c_str(), $3->getName().c_str());
			
			/* type check */
			if ($1->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}
			if ($3->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}
			/* Not exactly necessary, because rel_expression is set to int in shifting procedure */
			if ($1->getVarType() != "int" || $3->getVarType() != "int")
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Type mismatch for relational operator\n\n", lineCnt);
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
			fprintf(logFile, "At line no : %d rel_expression : simple_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("rel_expression");
		}
		| simple_expression RELOP simple_expression
		{
			fprintf(logFile, "At line no : %d rel_expression : simple_expression RELOP simple_expression\n\n", lineCnt);
			fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
					$2->getName().c_str(),
					$3->getName().c_str());

			/* checking function call */
			if ($1->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}
			if ($3->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
			}

			if ($1->getVarType() != "int" || $3->getVarType() != "int") 
			{
				SMNTC_ERR_COUNT++;
				fprintf(errorFile, "Line no %d : Type mismatch with mod operator\n\n", lineCnt)
			}
			symbolInfo *si = new symbolInfo(
				$1->getName()+$2->getName()+$3->getName(),
				"rel_expression"
			)
			si->setVarType("int");
			$$=si;
		}	
		;
				
simple_expression : term 
		{
			fprintf(logFile, "At line no : %d simple_expression : term\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("simple_expression");
		}
		| simple_expression ADDOP term 
		{
			fprintf(logFile, "At line no %d : simple_expression : simple_expression ADDOP term\n\n");
			fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
				$2->getName().c_str(),
				$3->getName().c_str());
			symbolInfo *si = new symbolInfo(
				$1->getName() + $2->getName() + $3->getName(),
				"simple_expression";
			);
			$$=si;
			
			/* type check */
			if ($1->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$1->setVarType("int");
			}
			if ($3->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
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
			fprintf(logFile, "At line no : %d term : unary_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("term");
		}
		|  term MULOP unary_expression
		{
			fprintf(logFile, "At line no : %d term : term MULOP unary_expression\n\n", lineCnt);
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
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$1->setVarType("int");
			}
			if ($3->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call within expression\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$3->setVarType("int");
			}
			
			if ($2->getName() == "%") 
			{
				$$->setVarType("int");
				if ($1->getVarType() != "int" || $2->getVarType() != "int")
				{
					SMNTC_ERR_COUNT++;
					fprintf(errorFile, "Line no %d : Type mismatch with mod operator\n\n", lineCnt)
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
			fprintf(logFile, "At line no : %d unary_expression : ADDOP unary_expression\n\n", lineCnt);
			fprintf(logFile, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str());
			symbolInfo *si = new symbolInfo($1->getName()+$2->getName(), "unary_expression");
			if ($2->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call inside expression\n\n", lineCnt);
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
			fprintf(logFile, "At line no : %d unary_expression : NOT unary_expression\n\n", lineCnt);
			fprintf(logFile, "!%s\n\n", $2->getName().c_str());
			symbolInfo *si = new symbolInfo("!"+$2->getName(), "unary_expression");
			if ($2->getVarType() == "void")
			{
				/* function cannot be called in expression */
				fprintf(errorFile, "Line no %d : void function call inside expression\n\n", lineCnt);
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
			fprintf(logFile, "At line no : %d unary_expression : factor\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("unary_expression");
		}
		;
	
factor	: variable 
	{
		fprintf(logFile, "At line no : %d factor : variable\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setType("factor");
	}
	| ID LPAREN argument_list RPAREN
	{
		fprintf(logFile, "At line no : %d factor : ID LPAREN argument_list RPAREN\n\n", lineCnt);
		fprintf(logFile, "%s(%s)\n\n", $1->getName().c_str(), $3->getName().c_str());
		/* unfinished - check if function and arguments list match*/
		$$ = new symbolInfo($1->getName() + "(" + $3->getName() + ")", "factor");
		symbolInfo *x = table->LookUp($1->getName());

		/* Check if the function name exists*/
		if (x == nullptr) {
			fprintf(errorFile, "Line no %d : no identifier found\n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}
		else if (x->getType() != "func_declaration" || x->getType() != "func_declaration"|| x->funcPtr == nullptr)
		{
			fprintf(errorFile, "Line no %d : function not declared or defined \n\n", lineCnt);
			SMNTC_ERR_COUNT++;
			$$->setVarType("int");
		}
		else 
		{ 
			/* match argument with param list */
			if(1) // if function doesnt have any parameter
			{

			}
			else if (x->getParamSize() != arg_vect.size()) 
			{
				// parameter size does not match
				fprintf(errorFile, "Line no %d : parameter and argument size does not match\n\n", lineCnt);
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
						fprintf(errorFile, "Line no %d : parameter and argument type does not match\n\n", lineCnt);
						SMNTC_ERR_COUNT++;
						$$->setVarType("int");
						break;
					}
				}
				if (i==arg_vect.size())
				{
					$$->setVarType(x->getVarType());
				}
			}
			
		}
		arg_vect.clear();
	}
	| LPAREN expression RPAREN
	{
		fprintf(logFile, "At line no : %d factor : LPAREN expression RPAREN\n\n", lineCnt);
		fprintf(logFile, "(%s)\n\n", $2->getName().c_str());
		symbolInfo *si = new symbolInfo("("+$2->getName()+")", "factor");
		$$=si;
		$$->setVarType($2->getVarType());
	}
	| CONST_INT 
	{
		fprintf(logFile, "At line no : %d factor : CONST_INT\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setVarType("int");
	}
	| CONST_FLOAT
	{
		fprintf(logFile, "At line no : %d factor : CONST_FLOAT\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
		$$->setVarType("float");
	}
	| variable INCOP 
	{
		fprintf(logFile, "At line no : %d factor : variable INCOP\n\n", lineCnt);
		fprintf(logFile, "%s++\n\n", $1->getName().c_str());
		$$ = new symbolInfo($1->getName()+"++", "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	| variable DECOP 
	{
		fprintf(logFile, "At line no : %d factor : variable DECOP\n\n", lineCnt);
		fprintf(logFile, "%s--\n\n", $1->getName().c_str());
		$$ = new symbolInfo($1->getName()+"--", "factor");
		$$->setVarType($1->getVarType()); /* type setting */
	}
	;
	
argument_list : arguments
		{
			fprintf(logFile, "At line no : %d argument_list : arguments\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
			$$->setType("argument_list");
		}
		|
		{
			fprintf(logFile, "At line no : %d argument_list : <epsilon>\n\n", lineCnt);
			fprintf(logFile, "\n\n");
			symbolInfo *si = new symbolInfo("", "argument_list");
			$$=si;
		}
		;
	
arguments : arguments COMMA logic_expression
		{
			fprintf(logFile, "At line no : %d arguments : arguments COMMA logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str());
			symbolInfo *si = new symbolInfo($1->getName()+","+$3->getName(), "arguments");
			if ($1->getVarType() == "void")
			{
				fprintf(errorFile, "Line no %d : void function called in argument of function\n\n", lineCnt);
				SMNTC_ERR_COUNT++;
				$1->setVarType("int");
			}
			$$ = si;
			arg_vect.push_back($3);
		}
		| logic_expression
		{
			fprintf(logFile, "At line no : %d arguments : logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=new symbolInfo($1->getname(), "arguments");
			if ($1->getVarType() == "void")
			{
				fprintf(errorFile, "Line no %d : void function called in argument of function\n\n", lineCnt);
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

	fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");
	

	yyin=fp;
	yyparse();
	

	fclose(fp2);
	fclose(fp3);
	
	return 0;
}

