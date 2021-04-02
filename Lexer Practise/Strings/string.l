%option noyywrap

%{

#include<iostream>
#include<string>
#include<cstring>
#include<cstdio>
#include<cstdlib>

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
    printf("<STRING, \"%s\">\n", str.c_str());
    //fprintf(logFile, "<STRING, \"%s\"> \n\n", str.c_str());
    //fprintf(tokenFile, "<STRING, \"%s\"> ", str.c_str());
}

%}

ALPHANUMERIC [a-zA-Z0-9]
WHITESPACE [ \t\f\r\v]+
DIGIT [0-9]
DIGITS [0-9]+

STRING_CHARS_NRML [^\n\r\"]
NEWLINE_FOR_MUL_LINE_STRING (\\\n|\\|\\\r\n)
STRING \"([^\"\\\n]|\\['\"?\\abfnrtv]|\\\n|\\\r\n)*\"

UNFINISHED_STRING_1 \"[^\"\n]*[^\\\"]\n
UNFINISHED_STRING_2 \"(([^\\])*\n|([^\\])*\r\n)\"
UNFINISHED_STRING_ERR \"([^\"\\\n]|\\\n)*(\n|\r\n)

%%
{STRING} {StringUtil(yytext);}
{UNFINISHED_STRING_ERR} {printf("<Error, %s >\n", yytext);}



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
	// \"([^\"\\\n]*[^\\]\n) string match
	
	yyin= fin;
	yylex();
	fclose(yyin);
	return 0;
	
}
