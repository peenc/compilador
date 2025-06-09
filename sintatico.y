%{
#include <iostream>
#include <string>
#include <sstream>
#include <vector> 
#include <map>
#include <stack>

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

struct simbolo {
    string nome;  
    string tipo;           
    string nome_interno;   
};


vector<simbolo> tabela_global;
vector<temporario> vetortemporarios;
int capacidade_temporarios = 100;
vector<map<string, simbolo>> pilhaDeTabelas;
int contadorEscopo = 0;
stack<int> pilhaEscopos;
vector<string> nomesDosEscopos;


int yylex(void);
void yyerror(string);
void adiciona_tabela_global(struct atributos variavel);
simbolo* busca_tabela_global(const string& nome);
bool existe_variavel_no_escopo_atual(const string& nome);
string imprime_tabela_global();
void abrir_escopo();
void fechar_escopo();
string gentempcode();
Atributos operacao(Atributos atr1, Atributos atr2, string op);
void armazenartemporarios(string var, string tipo);
string gerarvariavel(string tipo);
string gerarvariavel_de_usuario(const string& tipo, const string& nomeOriginal);
void adicionar_simbolo(string nome_original, string nome_interno, string tipo);
simbolo buscar_simbolo(const string& nome_original);
simbolo buscar_simbolo_por_interno(const string& nome_interno);
string imprimir_temporarios();
string imprimir_simbolos_escopo_atual();
string converter_bool_int(string traducao);
atributos operacao_relacional(atributos atr1, atributos atr2, string op);
void verificatipo(string atr1nome, string atr2nome);
string buscar_tipo_simbolo(const string& nome);
Atributos operacao_logica(atributos atr1, atributos atr2, string op);
Atributos operacao_not(atributos atr);
void verificaOperacao(atributos atr1, atributos atr2, string op);
Atributos verificaCoercao(Atributos &atr1, Atributos &atr2);
Atributos converteTipo(Atributos variavel);
bool tipoInvalidoParaOperacao(string tipo);
Atributos verificaTiposAtribuicao(string tipoVar, Atributos expr);
%}

%token TK_NUM TK_REAL TK_CHAR TK_LOGICO TK_STRING
%token TK_MAIN TK_ID TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_BOOLEAN TK_TIPO_CHAR TK_TIPO_STRING
%token TK_FIM TK_ERROR
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_DIFERENTE TK_IGUALDADE
%token TK_AND TK_OR
%token TK_IF TK_ELSE TK_WHILE
%token TK_PRINT TK_READ


%start S

%left TK_OR
%left TK_AND
%left TK_IGUALDADE TK_DIFERENTE
%left '<' '>' TK_MENOR_IGUAL TK_MAIOR_IGUAL
%left '+' '-'
%left '*' '/'
%right '!'





%%
S 		: INICIO	
		{
			$$ = $1; 
		}

INICIO 	: DECLR_TIPO ';' INICIO
		{
			
		}
		| MAIN 
		;


MAIN :  TK_TIPO_INT TK_MAIN '(' ')' BLOCO
		{
		    string codigo = "/*Compilador FOCA*/\n"
		                    "#include <iostream>\n"
		                    "#include<string.h>\n"
		                    "#include<stdio.h>\n";

		    codigo += imprime_tabela_global() + "\n";
		    codigo += "int main(void) {\n";
		    codigo += imprimir_simbolos_escopo_atual() + "\n";
		    codigo += imprimir_temporarios() + "\n";

		    codigo += $5.traducao;

		    codigo += "\treturn 0;\n}\n";

		    cout << codigo << endl;
		}
		;




BLOCO : '{'
 			{ abrir_escopo();}
  		COMANDOS 
		'}' 
  			{ fechar_escopo();
        $$.traducao = $3.traducao;
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


COMANDO 	:TK_IF '(' E ')' BLOCO
			{
			    string lbl = gentempcode();
			    // Tradução da expressão do if
			    $$.traducao = $3.traducao;
			    // Se a condição for falsa, pula para lbl (fim do bloco)
			    $$.traducao += "\tif (!" + $3.label + ") goto " + lbl + ";\n";
			    // Tradução do bloco do if
			    $$.traducao += $5.traducao;
			    // Label para continuar após o if
			    $$.traducao += lbl + ":\n";
			}

			| TK_IF '(' E ')' BLOCO TK_ELSE BLOCO
			{
			    string lbl_else = gentempcode();
			    string lbl_end = gentempcode();
			    // Tradução da expressão do if
			    $$.traducao = $3.traducao;
			    // Se a condição for falsa, pula para o else
			    $$.traducao += "\tif (!" + $3.label + ") goto " + lbl_else + ";\n";
			    // Tradução do bloco do if
			    $$.traducao += $5.traducao;
			    // Pula para o fim após o bloco if
			    $$.traducao += "\tgoto " + lbl_end + ";\n";
			    // Label do else
			    $$.traducao += lbl_else + ":\n";
			    // Tradução do bloco else
			    $$.traducao += $7.traducao;
			    // Label do fim
			    $$.traducao += lbl_end + ":\n";
			}
			| TK_WHILE '(' E ')' BLOCO
			{
				string lbl_inicio = gentempcode();
				string lbl_fim = gentempcode();

				// 1. Label para o início do laço (antes da condição)
				$$.traducao = lbl_inicio + ":\n";

				// 2. Código para avaliar a expressão condicional
				$$.traducao += $3.traducao;

				// 3. Se a condição for falsa, salta para fora do laço
				$$.traducao += "\tif (!" + $3.label + ") goto " + lbl_fim + ";\n";

				// 4. Código do corpo do laço
				$$.traducao += $5.traducao;

				// 5. Salto incondicional de volta ao início para reavaliar a condição
				$$.traducao += "\tgoto " + lbl_inicio + ";\n";

				// 6. Label para o fim do laço
				$$.traducao += lbl_fim + ":\n";
			}
			|TK_PRINT '(' E ')' ';'
		    {
		        // Se for string, usar %s
		        if ($3.tipo == "string") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%s\\n\", " + $3.label + ");\n";
		        }
		        // Se for int
		        else if ($3.tipo == "int") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%d\\n\", " + $3.label + ");\n";
		        }
		        // Se for float
		        else if ($3.tipo == "float") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%f\\n\", " + $3.label + ");\n";
		        }
		        // Se for char
		        else if ($3.tipo == "char") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%c\\n\", " + $3.label + ");\n";
		        }
		        // Se for bool
		        else if ($3.tipo == "bool") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%s\\n\", " + $3.label + " ? \"true\" : \"false\");\n";
		        }
		        else {
		            yyerror(("Não é possível imprimir o tipo " + $3.tipo).c_str());
		        }
		    }

		    | TK_READ '(' TK_ID ')' ';'
		    {
		        struct simbolo sim = buscar_simbolo($3.label);

		        if (sim.tipo == "") {
		            yyerror(("Variável não declarada: " + string($3.label)).c_str());
		        }

		        if (sim.tipo == "string") {
		            $$.traducao = "\tscanf(\"%s\", " + sim.nome_interno + ");\n";
		        }
		        else if (sim.tipo == "int") {
		            $$.traducao = "\tscanf(\"%d\", &" + sim.nome_interno + ");\n";
		        }
		        else if (sim.tipo == "float") {
		            $$.traducao = "\tscanf(\"%f\", &" + sim.nome_interno + ");\n";
		        }
		        else if (sim.tipo == "char") {
		            $$.traducao = "\tscanf(\" %c\", &" + sim.nome_interno + ");\n";
		        }
		        else if (sim.tipo == "bool") {
		            yyerror("Não é possível fazer leitura de tipo booleano.");
		        }
		        else {
		            yyerror(("Não é possível ler o tipo " + sim.tipo).c_str());
		        }
		    }

			| E ';'
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
			        struct simbolo sim = buscar_simbolo($1.label);
			        $$.label = sim.nome_interno;
			        $$.tipo = sim.tipo;
			        $$.traducao = "";
			    }
  			| TK_ID '=' E
			{
			    struct simbolo sim = buscar_simbolo($1.label);
			    if (sim.tipo == "") {
			        yyerror(("Variável não declarada: " + string($1.label)).c_str());
			    }

			    Atributos exprCorrigido = verificaTiposAtribuicao(sim.tipo, $3);

				if (sim.tipo == "string") {
				    $$.traducao = exprCorrigido.traducao + "\tstrcpy(" + sim.nome_interno + ", " + exprCorrigido.label + ");\n";
				} else {
				    $$.traducao = exprCorrigido.traducao + "\t" + sim.nome_interno + " = " + exprCorrigido.label + ";\n";
				}

				$$.label = sim.nome_interno;
				$$.tipo = sim.tipo;
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
			| TK_STRING
  			{
			    $$.tipo = "string";
			    $$.label = gerarvariavel("string");
			    $$.traducao += "\tstrcpy(" + $$.label + ", " + $1.label + ");\n";
  			}

			| DECLR_TIPO
			{
				$$.traducao = $1.traducao;
			}
			;
DECLR_TIPO : TK_TIPO_INT TK_ID
			{
			    string nome_original = $2.label;  // ou $2.valor, depende do seu token
			    string nome_interno = gerarvariavel_de_usuario("int", nome_original);
			    adicionar_simbolo(nome_original, nome_interno, "int");
			    $$.label = nome_interno;
			    $$.traducao = "\tint " + nome_interno + ";\n";
			 
			}

          	| TK_TIPO_FLOAT TK_ID
            {
                string nome_original = $2.label;
                string nome_interno = gerarvariavel_de_usuario("float", nome_original);
                adicionar_simbolo(nome_original, nome_interno, "float");
                $$.label = nome_interno;
                 $$.traducao = "\tfloat " + nome_interno + ";\n";
            }
          	| TK_TIPO_CHAR TK_ID
            {
                string nome_original = $2.label;
                string nome_interno = gerarvariavel_de_usuario("char", nome_original);
                adicionar_simbolo(nome_original, nome_interno, "char");
                $$.label = nome_interno;
                 $$.traducao = "\tchar " + nome_interno + ";\n";
                
            }
          	| TK_TIPO_BOOLEAN TK_ID
            {
                string nome_original = $2.label;
                string nome_interno = gerarvariavel_de_usuario("bool", nome_original);
                adicionar_simbolo(nome_original, nome_interno, "bool");
                $$.label = nome_interno;
                $$.traducao = "\tint " + nome_interno + ";\n";
                
            }
            DECLR_TIPO : TK_TIPO_STRING TK_ID
			{
			    string nome_original = $2.label;
			    string nome_interno = gerarvariavel_de_usuario("string", nome_original);
			    adicionar_simbolo(nome_original, nome_interno, "string");
			    $$.label = nome_interno;
			    $$.traducao = "\tchar " + nome_interno + "[256];\n";  // <- Aqui!
			}

;	


%%

#include "lex.yy.c"

int yyparse();

void abrir_escopo() {
    pilhaDeTabelas.push_back(map<string, simbolo>());
    nomesDosEscopos.push_back("escopo_" + to_string(contadorEscopo++));
}

// Fechar escopo
void fechar_escopo() {
    if (!pilhaDeTabelas.empty()) {
        pilhaDeTabelas.pop_back();
        nomesDosEscopos.pop_back();
    }
}

string obter_nome_escopo_atual() {
    if (pilhaDeTabelas.empty()) {
        return "global";
    } else {
        return nomesDosEscopos.back();
    }
}

string gerarvariavel_de_usuario(const string& tipo, const string& nomeOriginal) {
    string nomeInterno = "uservar_" + nomeOriginal + "_" + to_string(contadorEscopo);
    return nomeInterno;
}

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

bool existe_variavel_no_escopo_atual(const string& nome) {
    return !pilhaDeTabelas.empty() && pilhaDeTabelas.back().count(nome) > 0;
}
void adicionar_simbolo(string nome_original, string nome_interno, string tipo) {
    if (pilhaDeTabelas.empty()) {
        cout << "Erro: nenhum escopo aberto.\n";
        exit(1);
    }

    auto& escopo_atual = pilhaDeTabelas.back();

    if (escopo_atual.count(nome_original)) {
        cout << "Erro: variável '" << nome_original << "' já declarada no escopo atual.\n";
        exit(1);
    }

    simbolo s;
    s.nome = nome_original;
    s.nome_interno = nome_interno;
    s.tipo = tipo;

    escopo_atual[nome_original] = s;
}

simbolo buscar_simbolo(const string& nome_original) {
    for (auto it = pilhaDeTabelas.rbegin(); it != pilhaDeTabelas.rend(); ++it) {
        if (it->count(nome_original)) {
            return it->at(nome_original);
        }
    }

    cout << "Erro: variável '" << nome_original << "' não declarada.\n";
    exit(1);
}


simbolo buscar_simbolo_por_interno(const string& nome_interno) {
    // Procura nas tabelas de símbolos
    for (auto it = pilhaDeTabelas.rbegin(); it != pilhaDeTabelas.rend(); ++it) {
        for (auto& par : *it) {
            if (par.second.nome_interno == nome_interno) {
                return par.second;
            }
        }
    }

    // Procura nos temporários
    for (auto& temp : vetortemporarios) {
        if (temp.var == nome_interno) {
            simbolo simbolo_temp;
            simbolo_temp.nome_interno = nome_interno;
            simbolo_temp.tipo = temp.tipo;
            return simbolo_temp;
        }
    }

    cout << "Erro: símbolo '" << nome_interno << "' não encontrado.\n";
    exit(1);
}


string buscar_tipo_simbolo(const string& nome) {
    for (auto it = pilhaDeTabelas.rbegin(); it != pilhaDeTabelas.rend(); ++it) {
        if (it->count(nome)) {
            return it->at(nome).tipo;
        }
    }

    cout << "Erro: tipo da variável '" << nome << "' não encontrado.\n";
    exit(1);
}


// converte bool para int
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
        if (vetortemporarios[i].tipo == "bool") {
            strtemp += "\tint " + vetortemporarios[i].var + ";\n";
        }
        else if (vetortemporarios[i].tipo == "string") {
            strtemp += "\tchar " + vetortemporarios[i].var + "[256];\n";  // só isso para string
        }
        else {
            strtemp += "\t" + vetortemporarios[i].tipo + " " + vetortemporarios[i].var + ";\n";
        }
    }

    return strtemp;
}


string imprime_tabela_global() {
    stringstream ss;
    ss << "\n";
    if (!pilhaDeTabelas.empty()) {
        auto& escopo_global = pilhaDeTabelas.front();
        for (auto& par : escopo_global) {
            if (par.second.tipo == "string") {
                ss << "char " << par.second.nome_interno << "[256];\n";
            } else if (par.second.tipo == "bool") {
                ss << "int " << par.second.nome_interno << ";\n";
            } else {
                ss << par.second.tipo << " " << par.second.nome_interno << ";\n";
            }
        }
    }
    return ss.str();
}

string imprimir_simbolos_escopo_atual() {
    stringstream ss;
   
    if (pilhaDeTabelas.size() > 1) {
        auto& escopo = pilhaDeTabelas.back();
        for (auto& par : escopo) {
            ss << "\t" << par.second.tipo << " " << par.second.nome_interno
               << " (nome original: " << par.second.nome << ")\n";
        }
    }
    return ss.str();
}



void verificaOperacao(Atributos atr1, Atributos atr2, string op){
	
	// verificação para bool
	if(atr1.tipo == "bool" || atr2.tipo == "bool"){
		if(op == " + " || op == " - " || op == " * " || op == " / "){
			yyerror("Não é possivel realizar essa operação aritmética com booleanos: " + atr1.label + " " + op + " " + atr2.label );
		}
		if(op == " < " || op == " > " || op == " <= " || op == " >= "){
			yyerror("Não é possivel realizar essa operação relacional com booleanos: " + atr1.label + " " + op + " " + atr2.label );
		}
	}

	// verificação para string
	if(atr1.tipo == "string" || atr2.tipo == "string"){
		// Se for +, permitimos apenas se ambos forem string
		if(op == " + "){
			if(atr1.tipo != "string" || atr2.tipo != "string"){
				yyerror("Só é possível concatenar strings com strings.");
			}
			// concatenação permitida
		}
		else {
			// qualquer outro operador é inválido com strings
			yyerror("Operação '" + op + "' não é permitida com strings ");
		}
	}
}

Atributos operacao(Atributos atr1, Atributos atr2, std::string op) {
    Atributos resultado, var;

    // Verificar se operação é válida
    verificaOperacao(atr1, atr2, op);

    // Verificar coerção de tipos
    var = verificaCoercao(atr1, atr2);

    // Gerar label para o resultado
    resultado.label = gerarvariavel(var.tipo);
    resultado.tipo = var.tipo;

    // Construir código de tradução
    resultado.traducao = var.traducao;

    if (resultado.tipo == "string" && op == " + ") {
        // concatenação de string: usar strcpy + strcat
        resultado.traducao +=
            "\tstrcpy(" + resultado.label + ", " + atr1.label + ");\n" +
            "\tstrcat(" + resultado.label + ", " + atr2.label + ");\n";
    } else {
        // operação normal para tipos não string
        resultado.traducao +=
            "\t" + resultado.label + " = " + atr1.label + " " + op + " " + atr2.label + ";\n";
    }

    return resultado;
}


bool tipoInvalidoParaOperacao(string tipo) {
    return tipo == "char" || tipo == "bool";
}

Atributos converteTipo(Atributos variavel) {
    Atributos var;
    var.label = gerarvariavel("float");
    var.tipo = "float";
    var.traducao = variavel.traducao + "\t" + var.label + " = (float) " + variavel.label + ";\n";
    return var;
}

Atributos verificaCoercao(Atributos &atr1, Atributos &atr2) {
    Atributos var;

    if (tipoInvalidoParaOperacao(atr1.tipo) || tipoInvalidoParaOperacao(atr2.tipo)) {
        yyerror(("Não é possível realizar essa operação entre " 
                 + atr1.tipo + " e " + atr2.tipo).c_str());
    }

    if (atr1.tipo != atr2.tipo) {
        if (atr1.tipo == "int" && atr2.tipo == "float") {
            atr1 = converteTipo(atr1);
        } else if (atr1.tipo == "float" && atr2.tipo == "int") {
            atr2 = converteTipo(atr2);
        } else {
            yyerror(("Tipos incompatíveis: " + atr1.tipo + " e " + atr2.tipo).c_str());
        }
    }

    var.tipo = atr1.tipo;
    var.traducao = atr1.traducao + atr2.traducao;
    var.label = "";

    return var;
}


void verificatipo(string atr1nome, string atr2nome) {
    simbolo sim1 = buscar_simbolo_por_interno(atr1nome);
    simbolo sim2 = buscar_simbolo_por_interno(atr2nome);

    if (sim1.tipo == "bool" || sim2.tipo == "bool") {
        cout << "Erro de tipos entre '" << sim1.nome_interno << "' (tipo " << sim1.tipo << ")"
             << " e '" << sim2.nome_interno << "' (tipo " << sim2.tipo << ").\n";
        yyerror("Não é possível realizar a operação entre tipos booleanos.");
    }
}


atributos operacao_relacional(atributos atr1, atributos atr2, string op) {

	verificaOperacao(atr1,atr2,op);
	atributos resultado;
	resultado.tipo = "bool";
	resultado.label = gerarvariavel("bool");

	resultado.traducao = atr1.traducao + atr2.traducao;
	resultado.traducao += "\t" + resultado.label + " = " + atr1.label + op + atr2.label + ";\n";
	
	

	return resultado;
}

Atributos operacao_logica(Atributos atr1, Atributos atr2, string op){
	atributos resultado;
	
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
    simbolo sim = buscar_simbolo_por_interno(atr.label);

    if (sim.tipo != "bool") {
        yyerror("Operador '!' requer tipo booleano.");
    }

    atributos resultado;
    resultado.tipo = "bool";
    resultado.label = gerarvariavel("bool");
    resultado.traducao =
        atr.traducao +
        "\t" + resultado.label + " = !" + atr.label + ";\n";

    return resultado;
}

Atributos verificaTiposAtribuicao(string tipoVar, Atributos expr) {
    Atributos resultado = expr;

    if (tipoVar == expr.tipo) {
        return resultado;
    }

    // conversão int -> float (permitida)
    if (tipoVar == "float" && expr.tipo == "int") {
        resultado = converteTipo(expr);
        return resultado;
    }

    // conversão float -> int (permitida, mas gera cast explícito)
    if (tipoVar == "int" && expr.tipo == "float") {
        resultado.label = gerarvariavel("int");
        resultado.tipo = "int";
        resultado.traducao = expr.traducao +
                             "\t" + resultado.label + " = (int) " + expr.label + ";\n";
        return resultado;
    }

    // não pode conversão com bool
    if (tipoVar == "bool" || expr.tipo == "bool") {
        yyerror(("Não é permitido atribuir valores entre tipos booleanos e outros tipos: '"
                 + tipoVar + "' e '" + expr.tipo + "'").c_str());
    }

    // não pode conversão com string
    if (tipoVar == "string" || expr.tipo == "string") {
        yyerror(("Não é permitido atribuir valores entre tipos string e outros tipos: '"
                 + tipoVar + "' e '" + expr.tipo + "'").c_str());
    }

    yyerror(("Tipos incompatíveis na atribuição: variável do tipo '" + tipoVar +
             "' e expressão do tipo '" + expr.tipo + "'").c_str());

    return resultado;
}



int main(int argc, char* argv[]) {
    var_temp_qnt = 0;
    abrir_escopo();   // <--- Aqui abre o escopo global

    yyparse();

    fechar_escopo();  // <--- Fecha escopo global
    return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}	