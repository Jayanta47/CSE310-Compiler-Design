%option noyywrap yylineno

%x COMMENT
%x SINGLECOMMENT

%{

#include<string>
#include<iostream>
#include<cstdlib>

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+

%%

"/*" {BEGIN(COMMENT);
	printf("Comment started at %s, line %d\n", yytext, yylineno);}
"//" {BEGIN(SINGLECOMMENT);
	printf("Single comment started at %s, line %d\n", yytext, yylineno);}
<SINGLECOMMENT>([^\n]|(\\\n))* {printf("single comment: %s\n", yytext); }
<SINGLECOMMENT>(\n) {BEGIN(INITIAL);printf("return to initial\n");}
<COMMENT>"*/" {BEGIN(INITIAL); printf("return to initial\n");}

<COMMENT>([^*]|\*[^\/])* {printf("comment: %s\n", yytext);}
<COMMENT>\n {} 
(\n) {}
([^\/\*]|[^\/]+\*[ -~]?)* {printf("Initial: %s\n", yytext);}
<COMMENT><<EOF>> {printf("Unterminated Comment\n"); return 0;}


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
	yylineno = 1;
	yylex();
	fclose(yyin);
	return 0;
}

