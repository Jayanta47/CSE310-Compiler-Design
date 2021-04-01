%option noyywrap

%{

#include<stdio.h>
#include<stdlib.h>

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+
DIGIT [0-9]
DIGITS [0-9]+

FLOAT_VAR_ERR_TD1 ({DIGITS}\.{DIGITS})
FLOAT_VAR_TWO_TD2 (\.{DIGITS})
TOO_MANY_DECIMAL_POINTS_ERROR ({FLOAT_VAR_ERR_TD1}|{FLOAT_VAR_TWO_TD2})({FLOAT_VAR_ERR_TD1}|{FLOAT_VAR_TWO_TD2})*


VARIBALE_NAMING_ERROR [0-9][a-zA-Z0-9_]*
%%


{DIGITS}*\.({DIGIT}*|{DIGITS})\.([ -~])* {printf("too many decimal point, %s\n", yytext);}

{VARIBALE_NAMING_ERROR} {printf("variable naming error, %s\n", yytext);}

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
	
	//(({DIGIT}*\.|\.{DIGIT}+)\.{ALPHANUMERIC}*)+ {printf("too many decimal point, %s\n", yytext);}
	// {TOO_MANY_DECIMAL_POINTS_ERROR} {printf("too many decimal point, %s\n", yytext);}
}
