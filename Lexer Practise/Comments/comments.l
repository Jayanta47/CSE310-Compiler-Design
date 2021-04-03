%option noyywrap yylineno

%x COMMENT
%x SINGLECOMMENT

%{

#include<string>
#include<iostream>
#include<cstdlib>

std::string comnt = "";

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+

%%

"/*" {BEGIN(COMMENT);
	printf("Comment started at %s, line %d\n", yytext, yylineno);comnt = "";}
"//" {BEGIN(SINGLECOMMENT);
	printf("Single comment started at %s, line %d\n", yytext, yylineno);}
<SINGLECOMMENT>([^\n\\\r]|(\\\n)|(\\\r\n)|\\[^\n\r])* {printf("single comment: %s\n", yytext); }
<SINGLECOMMENT>(\n|\r\n) {BEGIN(INITIAL);printf("return to initial\n");}
<COMMENT>"*/" {BEGIN(INITIAL); 
printf("%s\n", comnt.c_str());
printf("return to initial\n");}

<COMMENT>([^\*\/])* {std::string s(yytext); comnt+=s;}
<COMMENT>\*/[^\/] {std::string s(yytext); comnt+=s;}

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

