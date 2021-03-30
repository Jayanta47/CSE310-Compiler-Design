%option noyywrap yylineno

%x COMMENT
%x SINGLECOMMENT

/* definition section */

%{

#include<iostream>
#include<string>
#include<cstring>
#include<cstdio>
#include<cstdlib>
#include "SymbolTable.h"

using namespace std;

FILE *logFile;
FILE *tokenFile;

// logFileName =  "log.txt";
// tokenFileName = "token.txt";

SymbolTable *symbolTable = new SymbolTable(20, "log.txt");

int ERR_COUNT = 0;

void InsertIntoSymTable(std::string Name, std::string Type) {
    bool accept = symbolTable->Insert(Name, Type);
    if (accept) {
        symbolTable->printAllScopeTable();
    }
}

void StringUtil(std::string s) {
    std::string str = "";
    for (int i = 0; i < s.size(); i++) {
        if (s[i]=='\\' && s[i+1] == 'n')
        {
            i++;
            str.push_back('\n');
        }
    }
}


%}


DIGIT [0-9]
DIGITS {DIGIT}+
ZERO_OR_MORE_DIGITS {DIGIT}*
LETTER [a-zA-Z]
ALPHANUMERIC ({DIGIT}|{LETTER})
WHITESPACE [ \t\f\r\v]+
NEWLINE [\n]

/* ----------------------------------------------------------------*/
/* keywords */
/* ----------------------------------------------------------------*/

IF "if"
ELSE "else"
FOR for 
WHILE "while"
DO "do"
BREAK "break" 
INT "int"
CHAR "char"
FLOAT "float"
DOUBLE "double"
VOID "void" 
RETURN "return"
SWITCH "switch"
CASE "case"
DEFAULT "default"
CONTINUE "continue" 

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* constants */
/* ----------------------------------------------------------------*/

/* Integer Literals */
CONST_INT {DIGITS}

/* Floating Point Literals */
/* Possible variations: */
/* Digit part - [digits.] , [.digits] , [digits.digits] */
/* Exponential part - (optional) E[digits], E[+digits], E[-digits] */  
EXPONENTIAL (Ee[-+]?{DIGITS})
CONST_FLOAT (({ZERO_OR_MORE_DIGITS}\.{DIGITS})|{DIGITS})({EXPONENTIAL})?

/* Character Literals */
/* There are normal characters(those within ASCII 32-126) */
/* and within them special characters */
/* '\n', '\t', '\\', '\'', '\a', '\f', '\r', '\b', '\v', '\0' */

NORMAL_CHARACTERS ([ -~]{-}['\\])
SPECIAL_CHARACTERS (\\[nt\\afrbv0\"])
CONST_CHAR ('{NORMAL_CHARACTERS}'|'{SPECIAL_CHARACTERS}')

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* operators and punctuators */
/* ----------------------------------------------------------------*/

ADDOP [-+]
MULOP [*/%]
INCOP ("++"|"--")
RELOP ("<"|"<="|">"|">="|"=="|"!=")
ASSIGNOP ("=")
LOGICOP ("&&"|"||")
NOT ("!")
LPAREN ("(")
RPAREN (")")
LCURL ("{")
RCURL ("}")
LTHIRD ("[")
RTHIRD ("]")
COMMA (",")
SEMICOLON (",")

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* identifiers */
/* ----------------------------------------------------------------*/

IDENTIFIER [{LETTER}_][{LETTER}{DIGIT}]

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* strings */
/* ----------------------------------------------------------------*/

STRING_CHARS_NRML [^{NEWLINE}\"]
NEWLINE_FOR_MUL_LINE_STRING (\\\n|\\\")
STRING \"({STRING_CHARS_NRML}|{NEWLINE_FOR_MUL_LINE_STRING})*\"

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* comments */
/* ----------------------------------------------------------------*/
/* done with state */


/* ----------------------------------------------------------------*/
/* errors */
/* ----------------------------------------------------------------*/

/* TOO MANY DECIMAL ERROR */
TOO_MANY_DECIMAL_POINT_ERR {DIGITS}*\.({DIGIT}*|{DIGITS})\.([ -~])*

/* ILL FORMED NUMBER ERROR */
ILL_FORMED_NUM_ERR (({ZERO_OR_MORE_DIGITS}\.{DIGITS})|{DIGITS})([Ee][-+]?)({CONST_FLOAT})

/* VARIABLE NAMING ERROR
INVALID_PREF_SUF_ERR {DIGIT}[{ALPHANUMERIC}_]*

/* MULTI CHARACTER CONSTANT ERROR */
MULTI_CHAR_ERR '({NORMAL_CHARACTERS}|{SPECIAL_CHARACTERS})({NORMAL_CHARACTERS}|{SPECIAL_CHARACTERS})+'

/* EMPTY CHARACTER CONSTANT ERROR
EMPTY_CHAR_ERR '({WHITESPACE})*'

/* UNFINISHED CHARACTER ERROR
RIGHT_APS_MISSING_IN_CHAR '({NORMAL_CHARACTERS}|{SPECIAL_CHARACTERS})*
SINGLE_FORWARD_SLASH_IN_CHAR '[\\]'
UNFINISHER_CHAR_ERR ({RIGHT_APS_MISSING_IN_CHAR}|{SINGLE_FORWARD_SLASH_IN_CHAR})

/* UNTERMINATED STRING
UNFINISHED_STRING_1 \"[^\"]* 
UNFINISHED_STRING_2 \"([^\n]*|[^\\]\n)\"
UNFINISHED_STRING_ERR ({UNFINISHED_STRING_1}|{UNFINISHED_STRING_2})

/* UNRECOGNIZED CHARACTER ERROR
UNRECOGNIZED_CHAR_ERR .

/* ----------------------------------------------------------------*/

/* rules section */
%%
"/*" {
    BEGIN(COMMENT);
    fprintf(logFile, "Line no %d, Token <COMMENT> Lexeme %s", yylineno, yytext);
}

<COMMENT>"*/" {
    BEGIN(INITIAL); 
    fprintf(logFile, "*/\n");
}

<COMMENT>([^*]|\*[^\/])* {fprintf(logFile, "%s", yytext);}

<COMMENT><<EOF>> {fprintf(logFile, "Unterminated Comment\n"); return 0;}

"//" {
    BEGIN(SINGLECOMMENT);
    fprintf(logFile, "Line no %d, Token <COMMENT> Lexeme %s", yylineno, yytext);
}

<SINGLECOMMENT>(\n) {
    BEGIN(INITIAL);
    fprintf(logFile, "*/\n");
}

<SINGLECOMMENT>([^\n]|(\\\n))* {
    fprintf(logFile, "%s", yytext);
}

{IF} {
    fprintf(tokenFile, "<IF>");
    fprintf(logFile, "Line no %d: Token <IF> Lexeme %s found\n\n", yylineno, yytext);
}

{ELSE} {
    fprintf(tokenFile, "<ELSE>");
    fprintf(logFile, "Line no %d: Token <ELSE> Lexeme %s found\n\n", yylineno, yytext);
}

{FOR} {
    fprintf(tokenFile, "<FOR>");
    fprintf(logFile, "Line no %d: Token <FOR> Lexeme %s found\n\n", yylineno, yytext);
}

{WHILE} {
    fprintf(tokenFile, "<WHILE>");
    fprintf(logFile, "Line no %d: Token <WHILE> Lexeme %s found\n\n", yylineno, yytext);
}

{DO} {
    fprintf(tokenFile, "<DO>");
    fprintf(logFile, "Line no %d: Token <DO> Lexeme %s found\n\n", yylineno, yytext);
}

{BREAK} {
    fprintf(tokenFile, "<BREAK>");
    fprintf(logFile, "Line no %d: Token <BREAK> Lexeme %s found\n\n", yylineno, yytext);
}

{INT} {
    fprintf(tokenFile, "<INT>");
    fprintf(logFile, "Line no %d: Token <INT> Lexeme %s found\n\n", yylineno, yytext);
}

{CHAR} {
    fprintf(tokenFile, "<CHAR>");
    fprintf(logFile, "Line no %d: Token <CHAR> Lexeme %s found\n\n", yylineno, yytext);
}

{FLOAT} {
    fprintf(tokenFile, "<FLOAT>");
    fprintf(logFile, "Line no %d: Token <FLOAT> Lexeme %s found\n\n", yylineno, yytext);
}

{DOUBLE} {
    fprintf(tokenFile, "<DOUBLE>");
    fprintf(logFile, "Line no %d: Token <DOUBLE> Lexeme %s found\n\n", yylineno, yytext);
}

{VOID} {
    fprintf(tokenFile, "<VOID>");
    fprintf(logFile, "Line no %d: Token <VOID> Lexeme %s found\n\n", yylineno, yytext);
}

{RETURN} {
    fprintf(tokenFile, "<RETURN>");
    fprintf(logFile, "Line no %d: Token <RETURN> Lexeme %s found\n\n", yylineno, yytext);
}

{SWITCH} {
    fprintf(tokenFile, "<SWITCH>");
    fprintf(logFile, "Line no %d: Token <SWITCH> Lexeme %s found\n\n", yylineno, yytext);
}

{CASE} {
    fprintf(tokenFile, "<CASE>");
    fprintf(logFile, "Line no %d: Token <CASE> Lexeme %s found\n\n", yylineno, yytext);
}

{DEFAULT} {
    fprintf(tokenFile, "<DEFAULT>");
    fprintf(logFile, "Line no %d: Token <DEFAULT> Lexeme %s found\n\n", yylineno, yytext);
}

{CONTINUE} {
    fprintf(tokenFile, "<CONTINUE>");
    fprintf(logFile, "Line no %d: Token <CONTINUE> Lexeme %s found\n\n", yylineno, yytext);
}

{LPAREN} {
    fprintf(tokenFile, "<LPAREN, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <LPAREN> Lexeme %s found\n\n", yylineno, yytext);
}

{RPAREN} {
    fprintf(tokenFile, "<RPAREN, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <RPAREN> Lexeme %s found\n\n", yylineno, yytext);
}

{LCURL} {
    fprintf(tokenFile, "<LCURL, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <LCURL> Lexeme %s found\n\n", yylineno, yytext);
}

{RCURL} {
    fprintf(tokenFile, "<RCURL, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <RCURL> Lexeme %s found\n\n", yylineno, yytext);
}

{LTHIRD} {
    fprintf(tokenFile, "<LTHIRD, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <LTHIRD> Lexeme %s found\n\n", yylineno, yytext);
}

{RTHIRD} {
    fprintf(tokenFile, "<RTHIRD, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <RTHIRD> Lexeme %s found\n\n", yylineno, yytext);
}

{COMMA} {
    fprintf(tokenFile, "<COMMA, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <COMMA> Lexeme %s found\n\n", yylineno, yytext);
}

{SEMICOLON} {
    fprintf(tokenFile, "<SEMICOLON, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <SEMICOLON> Lexeme %s found\n\n", yylineno, yytext);
}

{INCOP} {
    fprintf(tokenFile, "<INCOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <INCOP> Lexeme %s found\n\n", yylineno, yytext);
}

{ADDOP} {
    fprintf(tokenFile, "<ADDOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <ADDOP> Lexeme %s found\n\n", yylineno, yytext);
}

{MULOP} {
    fprintf(tokenFile, "<MULOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <MULOP> Lexeme %s found\n\n", yylineno, yytext);
}

{RELOP} {
    fprintf(tokenFile, "<RELOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <RELOP> Lexeme %s found\n\n", yylineno, yytext);
}

{LOGICOP} {
    fprintf(tokenFile, "<LOGICOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <LOGICOP> Lexeme %s found\n\n", yylineno, yytext);
}

{ASSIGNOP} {
    fprintf(tokenFile, "<ASSIGNOP, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <ASSIGNOP> Lexeme %s found\n\n", yylineno, yytext);
}

{NOT} {
    fprintf(tokenFile, "<NOT, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <NOT> Lexeme %s found\n\n", yylineno, yytext);
}

{CONST_INT} {
    fprintf(tokenFile, "<CONST_INT, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_INT> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "CONST_INT");
}

{CONST_FLOAT} {
    fprintf(tokenFile, "<CONST_FLOAT, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_FLOAT> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "CONST_FLOAT");
}

{CONST_CHAR} {
    fprintf(tokenFile, "<CONST_CHAR, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_CHAR> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "CONST_CHAR");
}

{IDENTIFIER} {
    fprintf(tokenFile, "<ID, %s>", yytext);
    fprintf(logFile, "Line no %d: Token <ID> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "ID");
}

{STRING} {
    StringUtil(yytext);
}

{TOO_MANY_DECIMAL_POINT_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Too many decimal points %s\n\n", yylineno, yytext);
}



{NEWLINE} {}

{WHITESPACE} {}

%%

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Please provide input file name and try again\n");
		return 0;
    }

    FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

    logFile = fopen("log.txt", "w");
    tokenFile = fopen("token.txt", "w");

    yyin= fin;
	yylex();

    fprintf(logFile, "Total lines: %d\nTotal errors: %d", yylineno, ERR_COUNT);
	fclose(yyin);
    fclose(logFile);
    fclose(tokenFile);
	return 0;

//     {INVALID_PREF_SUF_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", yylineno, yytext);
// }

// {ILL_FORMED_NUM_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Ill formed number %s\n\n", yylineno, yytext);    
// }

// {MULTI_CHAR_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Multi character constant error %s\n\n", yylineno, yytext);
// }

// {UNFINISHER_CHAR_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Unterminated character %s\n\n", yylineno, yytext);
// }

// {EMPTY_CHAR_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Empty character constant error %s\n\n", yylineno, yytext);
// }

// {UNFINISHED_STRING_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Unterminated String %s\n\n", yylineno, yytext);    
// }

// {UNRECOGNIZED_CHAR_ERR} {
//     ERR_COUNT++;
//     fprintf(logFile, "Error at line no %d: Unrecognized character error %s\n\n", yylineno, yytext);        
// }
}