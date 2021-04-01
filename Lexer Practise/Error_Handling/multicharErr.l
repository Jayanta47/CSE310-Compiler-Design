%option noyywrap

%{

#include<stdio.h>
#include<stdlib.h>

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+
DIGIT [0-9]
DIGITS [0-9]+

NORMAL_CHARACTER [ -~]{-}['\\]
SPECIAL_CHARACTER (\\[nt\\afrbv0\"])
MULTICHARERR '({NORMAL_CHARACTER}|{SPECIAL_CHARACTER})({NORMAL_CHARACTER}|{SPECIAL_CHARACTER})+'

EMPTY_CHAR_ERROR '({WHITESPACE})+'

RIGHT_APS_MISSING_IN_CHAR '({NORMAL_CHARACTER}|{SPECIAL_CHARACTER})*

SINGLE_FORWARD_SLASH_IN_CHAR '[\\]'

UNFINISHER_CHAR_ERR {RIGHT_APS_MISSING_IN_CHAR}|{SINGLE_FORWARD_SLASH_IN_CHAR}

VARIBALE_NAMING_ERROR [0-9][a-zA-Z0-9_]*

CONST_CHAR ('{NORMAL_CHARACTER}'|'{SPECIAL_CHARACTER}')
%%

{MULTICHARERR} { printf("multiple char error %s\n", yytext);}

{EMPTY_CHAR_ERROR} {printf("Empty character error %s\n", yytext);}

{UNFINISHER_CHAR_ERR} {printf("unfinished character error %s\n", yytext);}

{CONST_CHAR} {printf("character literal %s\n", yytext);}

%%

int main(int argc, char *argv[]) 
{
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	yyin= fin;
	yylex();
	fclose(yyin);
	return 0;
	
}
