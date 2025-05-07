%{
#include <iostream>
#include <string>
#include <sstream>
#include <vector> 

#define YYSTYPE atributos

using namespace std;

int var_temp_qnt = 0;

typedef struct atributos{	
	string tipo;
	string label;
	string traducao;
} Atributos;

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
Atributos operacao(Atributos atr1, Atributos atr2, string op);
void armazenartemporarios(string var, string tipo);
string gerarvariavel(string tipo);
string gerarvariavel_de_usuario(string tipo, string nome);
void adicionar_simbolo(string nome, string tipo);
struct simbolo buscar_simbolo(string nome);
string imprimir_temporarios();
string imprimir_simbolos();
string converter_bool_int(string traducao);
atributos operacao_relacional(atributos atr1, atributos atr2, string op);
void verificatipo(string atr1nome, string atr2nome);
string buscar_tipo_simbolo(string nome);
Atributos operacao_logica(atributos atr1, atributos atr2, string op);
Atributos operacao_not(atributos atr);
%}

%token TK_NUM TK_REAL TK_CHAR TK_LOGICO
%token TK_MAIN TK_ID TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_BOOLEAN TK_TIPO_CHAR
%token TK_FIM TK_ERROR
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_DIFERENTE TK_IGUALDADE
%token TK_AND TK_OR


%start S

%left '+' '-'
%left '*' '/'
%left '<' '>' TK_IGUALDADE TK_DIFERENTE TK_MAIOR_IGUAL TK_MENOR_IGUAL
%left TK_OR
%left TK_AND
%right '!'




%%

S : TK_TIPO_INT TK_MAIN '(' ')' BLOCO
    {
        string codigo = "/*Compilador FOCA*/\n"
                         "#include <iostream>\n"
                         "#include<string.h>\n"
                         "#include<stdio.h>\n"
                         "int main(void) {\n";
          
 		//codigo += imprimir_simbolos() +"\n";
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

COMANDO 	: E ';'
			{
				$$ = $1;
			}
			| E
			{
				$$ = $1;
			}
			| DECLR_TIPO
			{
				$$.traducao = "";
			}
			;

E 			: ARITMETICO
			{
				$$.traducao = $1.traducao;
			}
			| RELACIONAL
			{
				$$.traducao = $1.traducao;
			}
			| LOGICO
			{
				$$.traducao = $1.traducao;
			}

			| TK_ID
			{	
				struct simbolo sim = buscar_simbolo("uservar_" + $1.label);
				$$.label = sim.nome;
				$$.tipo = sim.tipo;
			}
    		| TK_ID '=' E
			{	
				struct simbolo sim = buscar_simbolo("uservar_" + $1.label);
				$$.traducao = $3.traducao + "\t" + sim.nome + " = " + $3.label + ";\n";

			}
			| '(' CAST ')' E 
			{
				$$.tipo = $2.tipo;
				$$.label = gerarvariavel($$.tipo);
				$$.traducao = $4.traducao + "\t" + $$.label + " = (" + $2.tipo + ") " + $4.label + ";\n";			
			}
    				

    		| TIPOS
    		{
    			$$.traducao = $1.traducao;
    		}
    		;

CAST 		: TK_TIPO_INT
			{
				$$.tipo = "int";
			}
			| TK_TIPO_FLOAT
			{
				$$.tipo = "float";
			}
			;
LOGICO		: E TK_AND E
			{	
			
				$$ = operacao_logica($1,$3, "&&");
			}
			| E TK_OR E
			{
				$$ = operacao_logica($1, $3, "||");
			}
			| '!' E
			{
	    		$$ = operacao_not($2);
			}


RELACIONAL  : E '<' E
			{
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, "<");
			}
			| E '>' E
			{	
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, " > ");
			}
			| E TK_IGUALDADE E
			{
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, " == ");
			}
			| E TK_DIFERENTE E
			{
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, " != ");
			}
			| E TK_MENOR_IGUAL E
			{
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, " <= ");
			}
			| E TK_MAIOR_IGUAL E
			{
				verificatipo($1.label, $3.label);
				$$ = operacao_relacional($1, $3, " >= ");
			}
			;
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
			| DECLR_TIPO
			{
				$$.traducao = $1.traducao;
			}
			;
DECLR_TIPO	: TK_TIPO_INT TK_ID
			{
				$$.label = gerarvariavel_de_usuario("int", $2.label);
				adicionar_simbolo($$.label, "int");
			}
			| TK_TIPO_FLOAT TK_ID
			{
				$$.label = gerarvariavel_de_usuario("float", $2.label);
				adicionar_simbolo($$.label, "float");
			}
			| TK_TIPO_CHAR TK_ID
			{				
				$$.label = gerarvariavel_de_usuario("char", $2.label);
				adicionar_simbolo($$.label, "char");
			}
			| TK_TIPO_BOOLEAN TK_ID
			{
				
				$$.label = gerarvariavel_de_usuario("bool", $2.label);
				adicionar_simbolo($$.label, "bool");
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

string gerarvariavel_de_usuario(string tipo, string nome)
{	
	string var = "uservar_"+ nome;
	armazenartemporarios(var, tipo);
	return var;
}

void adicionar_simbolo(string nome, string tipo){
	for(simbolo s : tabela_simbolos){
		if (s.nome == nome)
			return yyerror(s.nome + "Variável já declarada!");
	}
	tabela_simbolos.push_back({nome,tipo});
}

string buscar_tipo_simbolo(string nome) {
	for (simbolo s : tabela_simbolos) {
		if (s.nome == nome) {
			return s.tipo;
		}
	}
	return "";
}

struct simbolo buscar_simbolo(string nome) {
 
    
	for(int i = 0; i < tabela_simbolos.size(); i++){
    	if (tabela_simbolos[i].nome == nome) {
     		return tabela_simbolos[i];
    	}
    }
 	yyerror("variável" + nome + " não declarada"); 		
}

string converter_bool_int(string traducao){
    if(traducao == "true"){
        return "1";
    }
    return "0";
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

string imprimir_simbolos() {
	string strtemp;

	for (int i = 0; i < tabela_simbolos.size(); i++) {
		if(tabela_simbolos[i].tipo == "bool"){
			strtemp += "\tint " + tabela_simbolos[i].nome + ";\n";
		}
		else{
			strtemp += "\t" + tabela_simbolos[i].tipo + " " + tabela_simbolos[i].nome + ";\n";
		}
	}

	return strtemp;
}


Atributos operacao(Atributos atr1, Atributos atr2, string op){
	Atributos resultado;

	resultado.label = gerarvariavel("int");
	resultado.traducao = atr1.traducao + atr2.traducao + "\t" + resultado.label + " = " + atr1.label + op + atr2.label + ";\n";

	return resultado;

}


void verificatipo(string atr1nome, string atr2nome){
	
	string tipoaux1 = buscar_tipo_simbolo(atr1nome);
	string tipoaux2 = buscar_tipo_simbolo(atr2nome);
	
	if(tipoaux1 == "bool" || tipoaux2 == "bool"){
		yyerror("não é possível realizar a comparação entre os tipos!");

	}
}

atributos operacao_relacional(atributos atr1, atributos atr2, string op) {

	atributos resultado;
	resultado.tipo = "bool";
	resultado.label = gerarvariavel("bool");

	resultado.traducao = atr1.traducao + atr2.traducao;
	resultado.traducao += "\t" + resultado.label + " = " + atr1.label + op + atr2.label + ";\n";
	
	

	return resultado;
}

Atributos operacao_logica(Atributos atr1, Atributos atr2, string op){
	

	
	atributos resultado;
	
	cout<< atr1.label + "nomezinho dele" << endl;
	cout<< atr1.tipo + "tipo dele" << endl;
	
	if (atr1.tipo != "bool" || atr2.tipo != "bool") {
		if(op == "&&")
			yyerror("Operadores '&&' requerem tipos booleanos.");
		if(op == "||")
			yyerror("Operadores '||' requerem tipos booleanos.");
		else
			yyerror("Operador lógico inválido;");
	}

	

	resultado.tipo = "bool";
	resultado.label = gerarvariavel("bool");
	
	
	resultado.traducao =
        atr1.traducao +
        atr2.traducao +
        "\t" + resultado.label + " = " + atr1.label + " " + op + " " + atr2.label + ";\n";
    

	return resultado;
	

}

Atributos operacao_not(atributos atr) {
    
    string tipoaux = buscar_tipo_simbolo(atr.label);
	
    atributos resultado;

    if (tipoaux != "bool") {
        yyerror("Operador '!' requer tipo booleano.");
    }

    resultado.tipo = "bool";
    resultado.label = gerarvariavel("bool");
    resultado.traducao =
        atr.traducao +
        "\t" + resultado.label + " = !" + atr.label + ";\n";
    return resultado;
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
