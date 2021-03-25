%option noyywrap nodefault yylineno

/* definition section */

%{

#include<iostream>
#include<string>
#include<cstring>
#include<cstdio.h>
#include<cstdlib>
#include "SymbolTable.h"

using namespace std;

SymbolTable symbolTable(20, "output.txt");

FILE *logFile;
FILE *tokenFile;



%}


DIGIT [0-9]
DIGITS {DIGIT}+
ZERO_OR_MORE_DIGITS {DIGIT}*
LETTER [a-zA-Z]
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
EXPONENTIAL (E[-+]?{DIGITS})
CONST_FLOAT ({ZERO_OR_MORE_DIGITS}\.{DIGITS}|{DIGITS})({EXPONENTIAL})?

/* Character Literals */
/* There are normal characters(those within ASCII 32-126)
* and within them special characters
* '\n', '\t', '\\', '\'', '\a', '\f', '\r', '\b', '\v', '\0'
*/
NORMAL_CHARACTERS '([ -~]{-}['\\])'
SPECIAL_CHARACTERS '(\\[nt\\'afrbv0'])'
CONST_CHAR {NORMAL_CHARACTERS|SPECIAL_CHARACTERS}

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

