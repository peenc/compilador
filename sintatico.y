%{
#include <iostream>
#include <string>
#include <sstream>
#include <vector> 

#define YYSTYPE atributos

using namespace std;

int var_temp_qnt = 0;

struct atributos
{	
	string tipo;
	string label;
	string traducao;
};

struct temporario 
{
	string var;
	string tipo;
};

struct simbolo{
	string nome;
	string tipo;
};

vector<temporario> vetortemporarios;
int capacidade_temporarios = 100;
vector<simbolo> tabela_simbolos;


int yylex(void);
void yyerror(string);
string gentempcode();
struct atributos operacao(struct atributos atr1, struct atributos atr2, string op);
void armazenartemporarios(string var, string tipo);
string gerarvariavel(string tipo);
void adicionar_simbolo(string nome, string tipo);
string imprimir_temporarios();
string converter_bool_int(string traducao);
%}

%token TK_NUM TK_REAL TK_CHAR TK_LOGICO
%token TK_MAIN TK_ID TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_BOOLEAN TK_TIPO_CHAR
%token TK_FIM TK_ERROR
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_DIFERENTE TK_IGUALDADE

%start S

%left '+' '-'
%left '*' '/'


%%

S : TK_TIPO_INT TK_MAIN '(' ')' BLOCO
    {
        string codigo = "/*Compilador FOCA*/\n"
                         "#include <iostream>\n"
                         "#include<string.h>\n"
                         "#include<stdio.h>\n"
                         "int main(void) {\n";
          
 
        codigo += imprimir_temporarios() +"\n";
        codigo += $5.traducao;

        
        codigo += "\treturn 0;\n"
                  "\n}"; // Fechamento de main
		
        cout << codigo << endl;


    }
;



BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
			}
			;

COMANDOS	: COMANDO COMANDOS
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			{
				$$.traducao = "";
			}
			;

COMANDO 	: E 
			{
				$$ = $1;
			}
			;

E 			: ARITMETICO
			{
				$$.traducao = $1.traducao;
			}
			: RELACIONAL
			{
				$$.traducao = $1.traducao;
			}
    		| TK_ID '=' E
			{
				$$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n" ; //
			}
    		| TIPOS
    		{
    			$$.traducao = $1.traducao;
    		}
    		;

RELACIONAL  : E '<' E
			{
				//continuar daqui!!!!!!
			}

ARITMETICO  : E '+' E
			{
				$$ = operacao($1,$3," + ");
			}
			| E '-' E
			{
				$$ = operacao($1,$3," - ");
			}
			| E '*' E
			{
				$$ = operacao($1,$3," * ");
			}
			| E '/' E
			{
				$$ = operacao($1,$3," / ");
			}
			| '(' E ')'
    		{
        		$$ = $2; 
    		}
    		;

TIPOS 		: TK_LOGICO
			{
				$$.tipo = "bool";
				$$.label = gerarvariavel($$.tipo);
				string traducao = converter_bool_int($1.traducao);
				$$.traducao = "\t" + $$.label + " = " + traducao + ";\n";
			}
			| TK_NUM
			{	
				$$.tipo = "int";
				$$.label = gerarvariavel("int");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_REAL
			{	
				$$.tipo = "float";
				$$.label = gerarvariavel("float");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_CHAR
			{	
				$$.tipo = "char";
				$$.label = gerarvariavel("char");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ID
			{
				$$.label = gerarvariavel("int");
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			
			| DECLR_TIPO
			{
				$$.traducao = $1.traducao;
			}
			;
DECLR_TIPO	: TK_TIPO_INT TK_ID
			{
				adicionar_simbolo($2.label, "int");
				$$.label = $2.label;
			}
			| TK_TIPO_FLOAT TK_ID
			{
				adicionar_simbolo($2.label, "float");
				$$.label = $2.label;
			}
			| TK_TIPO_CHAR TK_ID
			{
				adicionar_simbolo($2.label, "char");
				$$.label = $2.label;
			}
			| TK_TIPO_BOOLEAN TK_ID
			{
				adicionar_simbolo($2.label, "bool");
				$$.label = $2.label;
			}
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
	string var = "t" + to_string(var_temp_qnt);
	return var;
}

string gerarvariavel(string tipo)
{	
	string var = gentempcode();
	armazenartemporarios(var,tipo);
	return var;
}

void armazenartemporarios(string var, string tipo) {
	vetortemporarios.push_back({var,tipo});
	
}

string imprimir_temporarios() {
	string strtemp;

	for (int i = 0; i < vetortemporarios.size(); i++) {
		if(vetortemporarios[i].tipo == "bool"){
			strtemp += "\tint " + vetortemporarios[i].var + ";\n";
		}
		else{
			strtemp += "\t" + vetortemporarios[i].tipo + " " + vetortemporarios[i].var + ";\n";
		}
	}

	return strtemp;
}


struct atributos operacao(struct atributos atr1, struct atributos atr2, string op){
	struct atributos resultado;

	resultado.label = gerarvariavel("int");
	resultado.traducao = atr1.traducao + atr2.traducao + "\t" + resultado.label + " = " + atr1.label + op + atr2.label + ";\n";

	return resultado;

}


void adicionar_simbolo(string nome, string tipo){
	for(simbolo s : tabela_simbolos){
		if (s.nome == nome)
			return yyerror(s.nome + "Variável já declarada!");
	}
	tabela_simbolos.push_back({nome,tipo});
}

string converter_bool_int(string traducao){
    if(traducao == "true"){
        return "1";
    }
    return "0";
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	yyparse();
	
	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}				
