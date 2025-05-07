%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*

%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"		{return TK_TIPO_INT;}

"float"		{return TK_TIPO_FLOAT;}

"bool"		{return TK_TIPO_BOOLEAN;}

"char"		{return TK_TIPO_CHAR;}


[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

[<]         { return *yytext; }
[>]         { return *yytext; }
"<="        { yylval.traducao = " <= "; return TK_MENOR_IGUAL; }
">="        { yylval.traducao = " => "; return TK_MAIOR_IGUAL; }
"!="        { yylval.traducao = " != "; return TK_DIFERENTE; }
"=="        { yylval.traducao = " == "; return TK_IGUALDADE; }


"true"   	{ yylval.traducao = "true"; return TK_LOGICO; }
"false"   	{ yylval.traducao = "false"; return TK_LOGICO; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{CHAR}		{ yylval.label = yytext; return TK_CHAR; }

"&&"        return TK_AND;
"||"        return TK_OR;
"!"         return '!';

.			{ *yytext; }

%%
