%option noyywrap 

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
#include "y.tab.h"

using namespace std;


//extern YYSTYPE yylval;
//extern SymbolTable *table;
void yyerror(char *);

int lineCnt = 1;
extern int ERR_COUNT;

extern FILE *logFile;
extern FILE *errorFile;



int tempCommentLineCnt;
std::string commentStr = "";


%}


DIGIT [0-9]
DIGITS {DIGIT}+
ZERO_OR_MORE_DIGITS {DIGIT}*
LETTER [a-zA-Z]
ALPHANUMERIC [{DIGIT}{LETTER}]
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
PRINTLN "println"
PRINTF "printf"

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
EXPONENTIAL [Ee][-+]?([0-9])+
/*CONST_FLOAT (({ZERO_OR_MORE_DIGITS}\.{DIGITS})|{DIGITS})({EXPONENTIAL})?*/
/*([0-9]*\.[0-9]+|[0-9]+\.)([Ee][-+]?([0-9])+)?|[0-9]+([Ee][-+]?([0-9])+)*/
CONST_FLOAT_VAR1 ([0-9]*\.[0-9]+|[0-9]+\.)({EXPONENTIAL})?
CONST_FLOAT_VAR2 [0-9]+({EXPONENTIAL})
CONST_FLOAT ({CONST_FLOAT_VAR1}|{CONST_FLOAT_VAR2})

/* Character Literals */
/* There are normal characters(those within ASCII 32-126) spcae to ~ */
/* and within them special characters */
/* '\n', '\t', '\\', '\'', '\a', '\f', '\r', '\b', '\v', '\0' */

NORMAL_CHARACTERS ([ -~]{-}['\\])
SPECIAL_CHARACTERS (\\[nt\\afrbv0\"\'])
CONST_CHAR ('{NORMAL_CHARACTERS}'|'{SPECIAL_CHARACTERS}')

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* operators and punctuators */
/* ----------------------------------------------------------------*/

ADDOP [-+]
MULOP [*/%]
INCOP "++"
DECOP "--"
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
SEMICOLON (";")

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* identifiers */
/* ----------------------------------------------------------------*/

IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* strings */
/* ----------------------------------------------------------------*/
CHARS_WITHOUT_Q_OR_SLASH_NL [^\"\\\n]
STR_SPECIAL_CHARS \\['\"?\\abfnrtv] 
SLASH_WITH_NRM_CHAR \\[A-Za-z]
STR_BRK_LINE (\\\n|\\\r\n)
STRING \"({CHARS_WITHOUT_Q_OR_SLASH_NL}|{STR_SPECIAL_CHARS}|{SLASH_WITH_NRM_CHAR}|{STR_BRK_LINE})*\"

/* ----------------------------------------------------------------*/


/* ----------------------------------------------------------------*/
/* comments */
/* ----------------------------------------------------------------*/
/* done with state */


/* ----------------------------------------------------------------*/
/* errors */
/* ----------------------------------------------------------------*/

/* TOO MANY DECIMAL ERROR */
TOO_MANY_DECIMAL_POINT_ERR [0-9]*\.[0-9]*\.[0-9\.]*

/* ILL FORMED NUMBER ERROR */
ILL_FORMED_NUM_ERR (([0-9]*\.[0-9]*)|[0-9]+)([Ee][-+]?([0-9])*\.[0-9\.]*)

/* VARIABLE NAMING ERROR */
INVALID_PREF_SUF_ERR {DIGIT}[a-zA-Z0-9_]*

/* MULTI CHARACTER CONSTANT ERROR */
MULTI_CHAR_ERR '({NORMAL_CHARACTERS}|{SPECIAL_CHARACTERS})([ -~]{-}[\'])+'

/* EMPTY CHARACTER CONSTANT ERROR */
EMPTY_CHAR_ERR '({WHITESPACE})*'

/* UNFINISHED CHARACTER ERROR */
RIGHT_APS_MISSING_IN_CHAR '({NORMAL_CHARACTERS}|(\\[nt\\afrbv0\"]))*
SINGLE_FORWARD_SLASH_IN_CHAR '[\\]'
UNFINISHER_CHAR_ERR ({RIGHT_APS_MISSING_IN_CHAR}|{SINGLE_FORWARD_SLASH_IN_CHAR}|("'\\"))


UNFINISHED_STRING_ERR \"([^\"\\\n]|\\['\"?\\abfnrtv]|\\[A-Za-z]|\\\n|\\\r\n)*(\n|\r\n)

/* UNRECOGNIZED CHARACTER ERROR */
UNRECOGNIZED_CHAR_ERR .

/* ----------------------------------------------------------------*/


/* rules section */
%%
"/*" {
    BEGIN(COMMENT);
    tempCommentLineCnt = lineCnt;
    commentStr = "";
}

<COMMENT>"*/" {
    BEGIN(INITIAL); 
}

<COMMENT>([^\*\n])* {
    std::string str(yytext);
    commentStr+=str;
}

<COMMENT>(\n) {
    lineCnt++;
    std::string str(yytext);
    commentStr+=str;
}

<COMMENT>\*/[^\/] {
    std::string str(yytext);
    commentStr+=str;
}


<COMMENT><<EOF>> {
    fprintf(errorFile, "Error at line no %d: Unterminated Comment /*%s*/\n\n", 
        tempCommentLineCnt, commentStr.c_str()); 
    ERR_COUNT++;
    return 0;
}

"//" {
    BEGIN(SINGLECOMMENT);
}

<SINGLECOMMENT>(\n|\r\n) {
    BEGIN(INITIAL);lineCnt++;
}

<SINGLECOMMENT>([^\n\\\r]|\\[^\n\r])* {}

<SINGLECOMMENT>((\\\n)|(\\\r\n)) {lineCnt++;}

{IF} { return IF; }

{ELSE} {return ELSE;}

{FOR} {return FOR;}

{WHILE} {return WHILE;}

{DO} {return DO;}

{BREAK} {return BREAK;}

{INT} {return INT;}

{CHAR} {return CHAR;}

{FLOAT} {return FLOAT;}

{DOUBLE} {return DOUBLE;}

{VOID} {return VOID;}

{RETURN} {return RETURN;}

{SWITCH} {return SWITCH;}

{CASE} {return CASE;}

{DEFAULT} {return DEFAULT;}

{CONTINUE} {return CONTINUE;}

{LPAREN} {return LPAREN;}

{RPAREN} {return RPAREN;}

{LCURL} {return LCURL;}

{RCURL} {return RCURL;}

{LTHIRD} {return LTHIRD;}

{RTHIRD} {return RTHIRD;}

{COMMA} {return COMMA;}

{SEMICOLON} {return SEMICOLON;}

{PRINTLN} {return PRINTLN;}

{PRINTF} {return PRINTF;}

{INCOP} {
    return INCOP;
}

{DECOP} {
    return DECOP;
}

{ADDOP} {
    symbolInfo *si = new symbolInfo(yytext, "ADDOP");
    yylval.symbol = si;
    return ADDOP;  
}

{MULOP} {
    symbolInfo *si = new symbolInfo(yytext, "MULOP");
    yylval.symbol = si;
    return MULOP;
}

{RELOP} {
    symbolInfo *si = new symbolInfo(yytext, "RELOP");
    yylval.symbol = si;
    return RELOP;
}

{LOGICOP} {
    symbolInfo *si = new symbolInfo(yytext, "LOGICOP");
    yylval.symbol = si;
    return LOGICOP;
}

{ASSIGNOP} {return ASSIGNOP;}

{NOT} {return NOT;}

{CONST_INT} {
    symbolInfo *si = new symbolInfo(yytext, "CONST_INT");
    yylval.symbol = si;
    return CONST_INT;
}

{CONST_FLOAT} {
    symbolInfo *si = new symbolInfo(yytext, "CONST_FLOAT");
    yylval.symbol = si;
    return CONST_FLOAT;    
}


{IDENTIFIER} {
    symbolInfo *si = new symbolInfo(yytext, "ID");
    yylval.symbol = si;
    return ID;
}

{TOO_MANY_DECIMAL_POINT_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Too many decimal points %s\n\n", lineCnt, yytext);
}

{INVALID_PREF_SUF_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", lineCnt, yytext);
}

{ILL_FORMED_NUM_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Ill formed number %s\n\n", lineCnt, yytext);    
}

{UNFINISHER_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Unterminated character %s\n\n", lineCnt, yytext);
}

{MULTI_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Multi character constant error %s\n\n", lineCnt, yytext);
}

{EMPTY_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Empty character constant error %s\n\n", lineCnt, yytext);
}


{NEWLINE} {lineCnt++;}

{WHITESPACE} {}

{UNRECOGNIZED_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: Unrecognized character %s\n\n", lineCnt, yytext);        
}


%%
