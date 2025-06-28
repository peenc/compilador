%{
#include <string>
%}

%option noyywrap
%option yylineno

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
"#".*         { /* Comentário ignorado */ }
\n         { yylineno++; }       
{DELIM}    { }

"main"     { return TK_MAIN; }
"int"      { return TK_TIPO_INT; }
"float"    { return TK_TIPO_FLOAT; }
"bool"     { return TK_TIPO_BOOLEAN; }
"char"     { return TK_TIPO_CHAR; }
"string"   { return TK_TIPO_STRING; }
"if"       { return TK_IF; }
"else"     { return TK_ELSE; }
"print"    { return TK_PRINT; }
"println"   return TK_PRINTLN;
"read"     { return TK_READ; }
"for"      { return TK_FOR; }
"while"    { return TK_WHILE; }
"do"       { return TK_DO; }
"break"    { return TK_BREAK; }
"continue" { return TK_CONTINUE; }
"switch"   { return TK_SWITCH; }
"case"     { return TK_CASE; }
"default"  { return TK_DEFAULT; }
"matriz"   { return TK_MATRIX; }
"vector"   { return TK_VECTOR; }
"return"   { return TK_RETURN; }
"void" {return TK_VOID;}

"(" { return '('; }
")" { return ')'; }
"{" { return '{'; }
"}" { return '}'; }
":" { return ':'; }
";" { return ';'; }
"," { return ','; }
"[" { return '['; }
"]" { return ']'; }

[+\-*/] { return *yytext; }
"="     { return '='; }
"++"    { yylval.label = strdup("++"); return TK_OP_UNARIO; }
"--"    { yylval.label = strdup("--"); return TK_OP_UNARIO; }

"<=" { return TK_MENOR_IGUAL; }
">=" { return TK_MAIOR_IGUAL; }
"!=" { return TK_DIFERENTE; }
"==" { return TK_IGUALDADE; }
"<"  { return '<'; }
">"  { return '>'; }

"+=" { yylval.label = "+="; return TK_OP_COMPOSTO; }
"-=" { yylval.label = "-="; return TK_OP_COMPOSTO; }
"*=" { yylval.label = "*="; return TK_OP_COMPOSTO; }
"/=" { yylval.label = "/="; return TK_OP_COMPOSTO; }
"%=" { yylval.label = "%="; return TK_OP_COMPOSTO; }


"true"  { yylval.traducao = "true"; return TK_LOGICO; }
"false" { yylval.traducao = "false"; return TK_LOGICO; }

{NUM}   { yylval.label = yytext; return TK_NUM; }
{REAL}  { yylval.label = yytext; return TK_REAL; }
{ID}    { yylval.label = yytext; return TK_ID; }
{CHAR}  { yylval.label = yytext; return TK_CHAR; }
{STRING} {
    std::string str(yytext);
    yylval.label = "\"" + str.substr(1, str.size() - 2) + "\"";
    return TK_STRING;
}

"&&" { return TK_AND; }
"||" { return TK_OR; }
"!"  { return '!'; }

. { return *yytext; }  // Isso fica no final mesmo

%%
