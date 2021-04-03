%option noyywrap

%{

#include<stdio.h>
#include<stdlib.h>

%}

ILL_FORMED_NUM_ERR (([0-9]*\.[0-9]*)|[0-9]+)([Ee][-+]?([0-9])*\.[0-9\.]*)

CONST_FLOAT_VAR1 ([0-9]*\.[0-9]+|[0-9]+\.)([Ee][-+]?([0-9])+)?
CONST_FLOAT_VAR2 [0-9]+([Ee][-+]?([0-9])+)
CONST_FLOAT ({CONST_FLOAT_VAR1}|{CONST_FLOAT_VAR2})
%%

{CONST_FLOAT} {printf("Float %s\n", yytext);}

{ILL_FORMED_NUM_ERR} {printf("Ill formed %s\n", yytext);}

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
