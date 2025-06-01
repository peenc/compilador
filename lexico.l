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
STRING \"([^\\\"]|\\.)*\"


%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"		{return TK_TIPO_INT;}

"float"		{return TK_TIPO_FLOAT;}

"bool"		{return TK_TIPO_BOOLEAN;}

"char"		{return TK_TIPO_CHAR;}

"string"    { return TK_TIPO_STRING; }

"if"        { return TK_IF; }

"else"      { return TK_ELSE; }


[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

"="		    { return '='; }

[<]         { return *yytext; }
[>]         { return *yytext; }
"<="        { return TK_MENOR_IGUAL; }
">="        { return TK_MAIOR_IGUAL; }
"!="        { return TK_DIFERENTE; }
"=="        { return TK_IGUALDADE; }



"true"   	{ yylval.traducao = "true"; return TK_LOGICO; }
"false"   	{ yylval.traducao = "false"; return TK_LOGICO; }

{NUM}		{ yylval.label = yytext; return TK_NUM; }
{REAL}		{ yylval.label = yytext; return TK_REAL; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{CHAR}		{ yylval.label = yytext; return TK_CHAR; }
{STRING} {
    std::string str(yytext);
    yylval.label = "\"" + str.substr(1, str.size() - 2) + "\"";
    return TK_STRING;
}

"&&"        return TK_AND;
"||"        return TK_OR;
"!"         return '!';

.			{ *yytext; }

%%
