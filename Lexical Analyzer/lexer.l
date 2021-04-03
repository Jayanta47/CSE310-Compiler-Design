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

std::string logFileName =  "log.txt";
std::string tokenFileName = "token.txt";

SymbolTable *symbolTable = new SymbolTable(7);

int ERR_COUNT = 0;
int tempCommentLineCnt;
std::string commentStr = "";

void InsertIntoSymTable(std::string Name, std::string Type) {
    bool accept = symbolTable->Insert(Name, Type);
    if (accept) {
        symbolTable->printAllScopeTable();
    }
}

// \"([^\"\\\n]|\\['\"?\\abfnrtv]|\\\n|\\\r\n)*\" java

void StringUtil(std::string s) {
    std::string str = "";
    for (int i = 0; i < s.size(); i++) {
        if (s[i] == '\"' && (i==0 || (i == s.size()-1))) {
            continue;
        }
        else if (s[i]=='\\' && s[i+1] == '\r' && s[i+2] == '\n' && i+1<s.size()) {
            i+=2;
        }
        else if (i+1<s.size() && s[i]=='\\' && s[i+1] == '\n')
        {
            i++;
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
    fprintf(logFile, "<STRING, \"%s\"> \n\n", str.c_str());
    fprintf(tokenFile, "<STRING, \"%s\"> ", str.c_str());
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
    fprintf(logFile, "<CONST_CHAR, %c> \n\n", ch);
    fprintf(tokenFile, "<CONST_CHAR, %c> ", ch);

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
/*CONST_FLOAT (({ZERO_OR_MORE_DIGITS}\.{DIGITS})|{DIGITS})({EXPONENTIAL})?*/
/*([0-9]*\.[0-9]+|[0-9]+\.)([Ee][-+]?([0-9])+)?|[0-9]+([Ee][-+]?([0-9])+)*/
CONST_FLOAT_VAR1 ([0-9]*\.[0-9]+|[0-9]+\.)([Ee][-+]?([0-9])+)?
CONST_FLOAT_VAR2 [0-9]+([Ee][-+]?([0-9])+)
CONST_FLOAT ({CONST_FLOAT_VAR1}|{CONST_FLOAT_VAR2})
/* Character Literals */
/* There are normal characters(those within ASCII 32-126) */
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

/*
STRING_CHARS_NRML [^{NEWLINE}\"]
NEWLINE_FOR_MUL_LINE_STRING (\\\n|\\\")
STRING \"({STRING_CHARS_NRML}|{NEWLINE_FOR_MUL_LINE_STRING})*\"
*/

STRING_CHARS_NRML [^\n\r\"]
NEWLINE_FOR_MUL_LINE_STRING (\\\n|\\|\\\r\n)
STRING \"([^\"\\\n]|\\['\"?\\abfnrtv]|\\[A-Za-z]|\\\n|\\\r\n)*\"


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
    tempCommentLineCnt = yylineno;
    commentStr = "";
}

<COMMENT>"*/" {
    BEGIN(INITIAL); 
    fprintf(logFile, "Line no %d: Token <COMMENT> Lexeme /*%s*/ found\n\n", tempCommentLineCnt, commentStr.c_str());
    commentStr = "";
    //fprintf(logFile, "*/ found\n\n");
}

<COMMENT>([^\*])* {
    std::string str(yytext);
    commentStr+=str;
}

<COMMENT>\*/[^\/] {
    std::string str(yytext);
    commentStr+=str;
}


<COMMENT><<EOF>> {
    fprintf(logFile, "Error at line no %d: Unterminated Comment /*%s*/\n\n", tempCommentLineCnt, commentStr.c_str()); 
    ERR_COUNT++;
    yylineno--;
    return 0;
}

"//" {
    BEGIN(SINGLECOMMENT);
    tempCommentLineCnt = yylineno;
    commentStr = "";
    //fprintf(logFile, "Line no %d: Token <COMMENT> Lexeme %s", yylineno, yytext);
}

<SINGLECOMMENT>(\n|\r\n) {
    BEGIN(INITIAL);
    fprintf(logFile, "Line no %d: Token <COMMENT> Lexeme //%s found\n\n", tempCommentLineCnt, commentStr.c_str());
    commentStr = "";
}

<SINGLECOMMENT>([^\n\\\r]|(\\\n)|(\\\r\n)|\\[^\n\r])* {
    std::string str(yytext);
    commentStr+=str;
}

{IF} {
    fprintf(tokenFile, "<IF> ");
    fprintf(logFile, "Line no %d: Token <IF> Lexeme %s found\n\n", yylineno, yytext);
}

{ELSE} {
    fprintf(tokenFile, "<ELSE> ");
    fprintf(logFile, "Line no %d: Token <ELSE> Lexeme %s found\n\n", yylineno, yytext);
}

{FOR} {
    fprintf(tokenFile, "<FOR> ");
    fprintf(logFile, "Line no %d: Token <FOR> Lexeme %s found\n\n", yylineno, yytext);
}

{WHILE} {
    fprintf(tokenFile, "<WHILE> ");
    fprintf(logFile, "Line no %d: Token <WHILE> Lexeme %s found\n\n", yylineno, yytext);
}

{DO} {
    fprintf(tokenFile, "<DO> ");
    fprintf(logFile, "Line no %d: Token <DO> Lexeme %s found\n\n", yylineno, yytext);
}

{BREAK} {
    fprintf(tokenFile, "<BREAK> ");
    fprintf(logFile, "Line no %d: Token <BREAK> Lexeme %s found\n\n", yylineno, yytext);
}

{INT} {
    fprintf(tokenFile, "<INT> ");
    fprintf(logFile, "Line no %d: Token <INT> Lexeme %s found\n\n", yylineno, yytext);
}

{CHAR} {
    fprintf(tokenFile, "<CHAR> ");
    fprintf(logFile, "Line no %d: Token <CHAR> Lexeme %s found\n\n", yylineno, yytext);
}

{FLOAT} {
    fprintf(tokenFile, "<FLOAT> ");
    fprintf(logFile, "Line no %d: Token <FLOAT> Lexeme %s found\n\n", yylineno, yytext);
}

{DOUBLE} {
    fprintf(tokenFile, "<DOUBLE> ");
    fprintf(logFile, "Line no %d: Token <DOUBLE> Lexeme %s found\n\n", yylineno, yytext);
}

{VOID} {
    fprintf(tokenFile, "<VOID> ");
    fprintf(logFile, "Line no %d: Token <VOID> Lexeme %s found\n\n", yylineno, yytext);
}

{RETURN} {
    fprintf(tokenFile, "<RETURN> ");
    fprintf(logFile, "Line no %d: Token <RETURN> Lexeme %s found\n\n", yylineno, yytext);
}

{SWITCH} {
    fprintf(tokenFile, "<SWITCH> ");
    fprintf(logFile, "Line no %d: Token <SWITCH> Lexeme %s found\n\n", yylineno, yytext);
}

{CASE} {
    fprintf(tokenFile, "<CASE> ");
    fprintf(logFile, "Line no %d: Token <CASE> Lexeme %s found\n\n", yylineno, yytext);
}

{DEFAULT} {
    fprintf(tokenFile, "<DEFAULT> ");
    fprintf(logFile, "Line no %d: Token <DEFAULT> Lexeme %s found\n\n", yylineno, yytext);
}

{CONTINUE} {
    fprintf(tokenFile, "<CONTINUE> ");
    fprintf(logFile, "Line no %d: Token <CONTINUE> Lexeme %s found\n\n", yylineno, yytext);
}

{LPAREN} {
    fprintf(tokenFile, "<LPAREN, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <LPAREN> Lexeme %s found\n\n", yylineno, yytext);
}

{RPAREN} {
    fprintf(tokenFile, "<RPAREN, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <RPAREN> Lexeme %s found\n\n", yylineno, yytext);
}

{LCURL} {
    fprintf(tokenFile, "<LCURL, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <LCURL> Lexeme %s found\n\n", yylineno, yytext);
    symbolTable->EnterScope();
}

{RCURL} {
    fprintf(tokenFile, "<RCURL, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <RCURL> Lexeme %s found\n\n", yylineno, yytext);
    symbolTable->ExitScope();
}

{LTHIRD} {
    fprintf(tokenFile, "<LTHIRD, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <LTHIRD> Lexeme %s found\n\n", yylineno, yytext);
}

{RTHIRD} {
    fprintf(tokenFile, "<RTHIRD, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <RTHIRD> Lexeme %s found\n\n", yylineno, yytext);
}

{COMMA} {
    fprintf(tokenFile, "<COMMA, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <COMMA> Lexeme %s found\n\n", yylineno, yytext);
}

{SEMICOLON} {
    fprintf(tokenFile, "<SEMICOLON, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <SEMICOLON> Lexeme %s found\n\n", yylineno, yytext);
}

{INCOP} {
    fprintf(tokenFile, "<INCOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <INCOP> Lexeme %s found\n\n", yylineno, yytext);
}

{ADDOP} {
    fprintf(tokenFile, "<ADDOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <ADDOP> Lexeme %s found\n\n", yylineno, yytext);
}

{MULOP} {
    fprintf(tokenFile, "<MULOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <MULOP> Lexeme %s found\n\n", yylineno, yytext);
}

{RELOP} {
    fprintf(tokenFile, "<RELOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <RELOP> Lexeme %s found\n\n", yylineno, yytext);
}

{LOGICOP} {
    fprintf(tokenFile, "<LOGICOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <LOGICOP> Lexeme %s found\n\n", yylineno, yytext);
}

{ASSIGNOP} {
    fprintf(tokenFile, "<ASSIGNOP, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <ASSIGNOP> Lexeme %s found\n\n", yylineno, yytext);
}

{NOT} {
    fprintf(tokenFile, "<NOT, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <NOT> Lexeme %s found\n\n", yylineno, yytext);
}

{CONST_INT} {
    fprintf(tokenFile, "<CONST_INT, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_INT> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "CONST_INT");
}

{CONST_FLOAT} {
    fprintf(tokenFile, "<CONST_FLOAT, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_FLOAT> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "CONST_FLOAT");
}

{CONST_CHAR} {
    //fprintf(tokenFile, "<CONST_CHAR, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <CONST_CHAR> Lexeme %s found --> ", yylineno, yytext);
    processConstChar(yytext);
    InsertIntoSymTable(yytext, "CONST_CHAR");
}

{IDENTIFIER} {
    fprintf(tokenFile, "<ID, %s> ", yytext);
    fprintf(logFile, "Line no %d: Token <ID> Lexeme %s found\n\n", yylineno, yytext);
    InsertIntoSymTable(yytext, "ID");
}

{STRING} {
    //printf("String found %s\n", yytext);
    std::string s(yytext);
    int newLineCntr = 0;
    for(int i = 0; i < s.size(); i++)
    {
        if (s[i] == '\n') {
            newLineCntr++;
        }
    }
    fprintf(logFile, "Line no %d: Token <STRING> Lexeme %s found --> ", yylineno-newLineCntr, yytext);
    StringUtil(yytext);
}

{TOO_MANY_DECIMAL_POINT_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Too many decimal points %s\n\n", yylineno, yytext);
}

{INVALID_PREF_SUF_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n", yylineno, yytext);
}

{ILL_FORMED_NUM_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Ill formed number %s\n\n", yylineno, yytext);    
}

{UNFINISHER_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Unterminated character %s\n\n", yylineno, yytext);
}

{MULTI_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Multi character constant error %s\n\n", yylineno, yytext);
}

{EMPTY_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Empty character constant error %s\n\n", yylineno, yytext);
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
    printf("%s - > %d\n", str.c_str(), yylineno);
    str.pop_back();
    printf("%ld\n", str.size());
    printf("%s -> %d\n", str.c_str(), yylineno);
    fprintf(logFile, "Error at line no %d: Unterminated String %s\n\n", yylineno-newLineCntr, str.c_str());    
}


{NEWLINE} {}

{WHITESPACE} {}

{UNRECOGNIZED_CHAR_ERR} {
    ERR_COUNT++;
    fprintf(logFile, "Error at line no %d: Unrecognized character %s\n\n", yylineno, yytext);        
}


%%

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Please provide input file name and try again\n");
		return 0;
    }

    FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

    printf("%d\n", argc);
    printf("logFilename = %s\n", argv[2]);
    printf("tokenFileName = %s\n", argv[3]);

    logFileName = argv[2];
    tokenFileName = argv[3];
    logFile = fopen(logFileName.c_str(), "w");
    tokenFile = fopen(tokenFileName.c_str(), "w");

    symbolTable->setFileWriter(logFile);

    yyin= fin;
	yylex();

    symbolTable->printAllScopeTable();

    fprintf(logFile, "Total lines: %d\nTotal errors: %d", yylineno, ERR_COUNT);
	fclose(yyin);
    fclose(logFile);
    fclose(tokenFile);
	return 0;

//     ./lexer.out input1.txt log1.txt token1.txt
// ./lexer.out input3.txt log3.txt token3.txt
// ./lexer.out input4.txt log4.txt token4.txt
// ./lexer.out input5.txt log5.txt token5.txt

}