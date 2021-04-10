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

std::string code_segm;
vector<string> code_vect;
SymbolTable *table;


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

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHID COMMA SEMICOLON NOT PRINTLN
%token<symbol>CONST_INT
%token<symbol>CONST_FLOAT
%token<symbol>CONST_CHAR
%token<symbol>ID
%token<symbol>ADDOP
%token<symbol>MULOP
%token<symbol>RELOP
%token<symbol>LOGICOP
%token<symbol>INCOP
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
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
		| type_specifier ID LPAREN RPAREN compound_statement
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		| parameter_list COMMA type_specifier
 		| type_specifier ID
		| type_specifier
 		;

 		
compound_statement : LCURL statements RCURL
 		    | LCURL RCURL
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON
 		 ;
 		 
type_specifier	: INT
		{
			fprintf(logFile, "At line no : %d type_specifier : INT\n\n", lineCnt);

			symbolInfo *type = new symbolInfo("int");
			$$ = type;
			fprintf(logFile, "int\n\n"); 
		}
 		| FLOAT
		{
			fprintf(logFile, "At line no : %d type_specifier : FLOAT\n\n", lineCnt);

			symbolInfo *type = new symbolInfo("float");
			$$ = type;
			fprintf(logFile, "float\n\n");
		}
 		| VOID
		{
			fprintf(logFile, "At line no : %d type_specifier : VOID\n\n", lineCnt);

			symbolInfo *type = new symbolInfo("void");
			$$ = type;
			fprintf(logFile, "void\n\n");
		}
 		;
 		
declaration_list : declaration_list COMMA ID
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		  | ID
 		  | ID LTHIRD CONST_INT RTHIRD
 		  ;
 		  
statements : statement
	{
		fprintf(logFile, "At line no : %d statements : statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
	}
	| statements statement
	;
	   
statement : var_declaration
	{
		fprintf(logFile, "At line no : %d statement : var_declaration\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
	}
	| expression_statement
	{
		fprintf(logFile, "At line no : %d statement : expression_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
	}
	| compound_statement
	{
		fprintf(logFile, "At line no : %d statement : compound_statement\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "for("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	| IF LPAREN expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : IF LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		fprintf(logFile, "At line no : %d statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", lineCnt);
		std::string statementC = "if("+$3->getName()+")"+$5->getname()+"else"+$7->getName();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	| WHILE LPAREN expression RPAREN statement
	{
		fprintf(logFile, "At line no : %d statement : WHILE LPAREN expression RPAREN statement\n\n", lineCnt);
		std::string statementC = "while("+$3->getName()+")"+$5->getname();
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		fprintf(logFile, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineCnt);
		std::string statementC = "println("+$3->getName()+")"+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	| RETURN expression SEMICOLON
	{
		fprintf(logFile, "At line no : %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", lineCnt);
		std::string statementC = "println("+$3->getName()+")"+";";
		fprintf(logFile, "%s\n\n", statementC.c_str());
		symbolInfo *si = new symbolInfo(statementC, "statement");
		$$=si;
	}
	;
	  
expression_statement 	: SEMICOLON			
	{
		fprintf(logFile, "At line no : %d expression_statement : SEMICOLON\n\n", lineCnt);
		fprintf(logFile, ";\n\n");

		symbolInfo *si = new symbolInfo(";", "expression_statement");
		$$ = si;
	}
	| expression SEMICOLON
	{
		fprintf(logFile, "At line no : %d expression_statement : expression SEMICOLON\n\n");
		fprintf(logFile, "%s;\n\n", $1->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName() + ";", "expression_statement");
		si->setVarType($1->getVarType());
		$$=si;
	} 
	;
	  
variable : ID 		
	{
		fprintf(logFile, "At line no : %d variable : ID\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());

		$$ = $1;
		$$->setIDType("variable");
		// check if this variable already exists in symbol table
		symbolInfo *si = table->LookUp($$->getName());
		if (si) 
		{
			$$->setVarType($1->getVarType()); // variable declaration is okay
		}
		else 
		{
			fprintf(errorFile, "Line no %d : undeclared variable name");
			SMNTC_ERR_COUNT++;
		}
	}
	 | ID LTHIRD expression RTHIRD 
	{
		fprintf(logFile, "At line no : %d variable : ID LTHIRD expression RTHIRD\n\n", lineCnt);
		fprintf(logFile, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str());

		//check if expression is int
		if ($3->getVarType() != "int")
		{
			SMNTC_ERR_COUNT++;
			fprintf(errorFile, "Line no %d : Invalid datatype for index\n\n");
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
			si->arrIndex = index;
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
		}
	   | variable ASSIGNOP logic_expression
	   {
		   
	   } 	
	   ;
			
logic_expression : rel_expression 	
		{
			fprintf(logFile, "At line no : %d logic_expression : rel_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
		}
		| rel_expression LOGICOP rel_expression 	
		{
			fprintf(logFile, "At line no : %d logic_expression : rel_expression LOGICOP rel_expression\n\n");
			fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
					$2->getName().c_str(), $3->getName().c_str());
			
			if ($1->getName() != "int" || $3->getName() != "int")
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
		}
		| simple_expression RELOP simple_expression
		{
			fprintf(logFile, "At line no : %d rel_expression : simple_expression RELOP simple_expression\n\n", lineCnt);
			fprintf(logFile, "%s%s%s\n\n", $1->getName().c_str(),
					$2->getName().c_str(),
					$3->getName().c_str());
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
			si->setVarType($2->getVarType());
			$$=si;
		}
		| NOT unary_expression 
		{
			fprintf(logFile, "At line no : %d unary_expression : NOT unary_expression\n\n", lineCnt);
			fprintf(logFile, "!%s\n\n", $2->getName().c_str());
			symbolInfo *si = new symbolInfo("!"+$2->getName(), "unary_expression");
			si->setVarType($2->getVarType());
			$$=si;
		}
		| factor 
		{
			fprintf(logFile, "At line no : %d unary_expression : factor\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
		}
		 ;
	
factor	: variable 
	{
		fprintf(logFile, "At line no : %d factor : variable\n\n", lineCnt);
		fprintf(logFile, "%s\n\n", $1->getName().c_str());
		$$=$1;
	}
	| ID LPAREN argument_list RPAREN
	{
		fprintf(logFile, "At line no : %d factor : ID LPAREN argument_list RPAREN\n\n", lineCnt);
		fprintf(logFile, "%s(%s)\n\n", $1->getName().c_str(), $3->getName().c_str());
		/* unfinished - check if function and arguments list match

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
		fprintf(logFile, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str());
		symbolInfo *si = new symbolInfo($1->getName()+$2->getName(), "factor");
		$$=si;
		$$->setVarType($1->getVarType());
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
			symbolInfo *si = new symbolInfo("", "argument_list");
			$$=si;
		}
		;
	
arguments : arguments COMMA logic_expression
		{
			fprintf(logFile, "At line no : %d arguments : arguments COMMA logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str());
			symbolInfo *si = new symbolInfo($1->getName()+","+$3->getName(), "arguments");
			$$ = si;
			arg_vect.push_back($3);
		}
		| logic_expression
		{
			fprintf(logFile, "At line no : %d arguments : logic_expression\n\n", lineCnt);
			fprintf(logFile, "%s\n\n", $1->getName().c_str());
			$$=$1;
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

