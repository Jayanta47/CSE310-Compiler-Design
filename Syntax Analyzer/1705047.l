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
#include "1705047_SymbolTable.h"
#include "y.tab.h"

using namespace std;


//extern YYSTYPE yylval;
//extern SymbolTable *table;
void yyerror(char *);

int lineCnt = 1;
extern int ERR_COUNT;

extern FILE *logFile;
extern FILE *errorFile;

// std::string logFileName =  "1705047_log.txt";
// std::string tokenFileName = "1705047_token.txt";

int tempCommentLineCnt;
std::string commentStr = "";


void StringUtil(std::string s) {
    std::string str = "";
    for (int i = 0; i < s.size(); i++) {
        if (s[i] == '\"' && (i==0 || (i == s.size()-1))) {
            continue;
        }
        else if (s[i]=='\\' && s[i+1] == '\r' && s[i+2] == '\n' && i+1<s.size()) {
            i+=2;lineCnt++;
        }
        else if (i+1<s.size() && s[i]=='\\' && s[i+1] == '\n')
        {
            i++;lineCnt++;
        }
        else if (s[i] == '\\') {
            if (s[i+1] == 't') s[i+1] = '\t';
            else if (s[i+1] == 'n') s[i+1] = '\n';
            else if (s[i+1] == '\\') s[i+1] = '\\';
            else if (s[i+1] == '\'') s[i+1] = '\'';
            else if (s[i+1] == 'a') s[i+1] = '\a';
            else if (s[i+1] == 'f') s[i+1] = '\f';
            else if (s[i+1] == 'r') s[i+1] = '\r';
            else if (s[i+1] == 'b') s[i+1] = '\b';
            else if (s[i+1] == 'v') s[i+1] = '\v';
            else if (s[i+1] == '0') s[i+1] = '\0';
            else if (s[i+1] == '\"') s[i+1] = '\"';
        }
        else {
            str.push_back(s[i]);
        }
    }

    printf("%s\n", str.c_str());

    symbolInfo *si = new symbolInfo(str.c_str(), "STRING");
    yylval.symbol = si;
}

void processConstChar(std::string str) {
    char ch;
    if (str.size() == 3 && str[0] == '\'' && str[2] == '\'') {
        ch = str[1];
    }
    else if (str[1] == '\\'){
        char sc = str[2];
        switch (sc) {
            case 'n':
                ch = '\n';
                break;
            case 't':
                ch = '\t';
                break;
            case '\\':
                ch = '\\';
                break;
            case 'a':
                ch = '\a';
                break;
            case 'f':
                ch = '\f';
                break;
            case 'r':
                ch = '\r';
                break;
            case 'b':
                ch = '\b';
                break;
            case 'v':
                ch = '\v';
                break;
            case '0':
                ch = '\0';
                break;
            case '\"':
                ch = '\"';
                break;
            case '\'':
                ch = '\'';
                break;
            default:
                break;
        } 

    }
    else return;
    symbolInfo *si = new symbolInfo(ch, "CONST_CHAR");
    yylval.symbol = si;
} 


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

{INT} {return INT'}

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

{INCOP} {
    symbolInfo *si = new symbolInfo(yytext, "INCOP");
    yylval.symbol = si;
    return INCOP;
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

{CONST_CHAR} {
    processConstChar(yytext);
    return CONST_CHAR;
}

{IDENTIFIER} {
    symbolInfo *si = new symbolInfo(yytext, "ID");
    yylval.symbol = si;
    return ID;
}

{STRING} {
    StringUtil(yytext);
}

{TOO_MANY_DECIMAL_POINT_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Too many decimal points %s\n\n", lineCnt, yytext);
}

{INVALID_PREF_SUF_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Invalid prefix on ID or invalid suffix on Number %s\n\n", lineCnt, yytext);
}

{ILL_FORMED_NUM_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Ill formed number %s\n\n", lineCnt, yytext);    
}

{UNFINISHER_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Unterminated character %s\n\n", lineCnt, yytext);
}

{MULTI_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Multi character constant error %s\n\n", lineCnt, yytext);
}

{EMPTY_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Empty character constant error %s\n\n", lineCnt, yytext);
}

{UNFINISHED_STRING_ERR} {
    ERR_COUNT++;
    std::string str(yytext);
    int newLineCntr = 0;
    for(int i = 0; i < str.size(); i++)
    {
        if (str[i] == '\n') {
            newLineCntr++;
        }
    }
    str.pop_back();
    fprintf(errorFile, "Error at line no %d: 
        Unterminated String %s\n\n", lineCnt-newLineCntr, str.c_str());    
}


{NEWLINE} {lineCnt++;}

{WHITESPACE} {}

{UNRECOGNIZED_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(errorFile, "Error at line no %d: 
        Unrecognized character %s\n\n", lineCnt, yytext);        
}


%%