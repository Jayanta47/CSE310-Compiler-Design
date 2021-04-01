%option noyywrap

%x COMMENT
%x SINGLECOMMENT

%{

#include<stdio.h>
#include<stdlib.h>

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+

%%

"/*" {BEGIN(COMMENT);
	printf("Comment started at %s\n", yytext);}
"//" {BEGIN(SINGLECOMMENT);
	printf("Single comment started at %s\n", yytext);}
<SINGLECOMMENT>([^\n]|(\\\n))* {printf("single comment: %s\n", yytext); }
<SINGLECOMMENT>(\n) {BEGIN(INITIAL);printf("return to initial\n");}
<COMMENT>"*/" {BEGIN(INITIAL); printf("return to initial\n");}

<COMMENT>([^*]|\*[^\/])* {printf("comment: %s\n", yytext);}
(^\*\\)* {printf("Initial: %s\n", yytext);}

%%
int main(int argc, char *argv[]) {
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
//<COMMENT>(([ -~]{-}"*/")|\n)+ {printf("comment: %s\n", yytext);}
	yyin= fin;
	yylex();
	fclose(yyin);
	return 0;
}

