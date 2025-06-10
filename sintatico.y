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
int contador_label_loop = 0;
int contador_label_switch = 0;
int var_if_qnt = 0;

typedef struct atributos{	
	string tipo;
	string label;
	string traducao;
	string inicio_loop;  // adiciona essa linha
    string fim_loop;     // e essa linha
    string incremento_loop;
    string ifs;           // códigos dos ifs que testam os valores do switch
    string blocks;        // códigos dos blocos que executam os cases
    string default_block; // bloco do default (se houver)
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

struct loop
{
	string inicio_loop;
	string fim_loop;
	string incremento_loop;
	string nome;

} typedef loop;

struct SwitchContext {
    string cond_var;      // apelido da variável da expressão do switch (apelido_cond)
    string lbl_fim;       // label do fim do switch
}typedef switchcase;

enum TipoContexto { CONTEXTO_LOOP, CONTEXTO_SWITCH };

struct ContextoControle {
    TipoContexto tipo;
    string lbl_inicio;
    string lbl_fim;
    string lbl_incremento; 
};

vector<ContextoControle> controle_stack;

vector<loop> loops;
vector<loop> limites_loop;
int contador = 0;
int contador_loop = 0;
vector<SwitchContext> switch_stack;

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
string gentempcodeloop();
string gentempcodeif();
string gentempcodeswitch();
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
loop criar_contexto_loop(bool tem_incremento);
switchcase criar_contexto_switch();



%}

%token TK_NUM TK_REAL TK_CHAR TK_LOGICO TK_STRING
%token TK_MAIN TK_ID TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_BOOLEAN TK_TIPO_CHAR TK_TIPO_STRING
%token TK_FIM TK_ERROR
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_DIFERENTE TK_IGUALDADE
%token TK_AND TK_OR
%token TK_IF TK_ELSE
%token TK_PRINT TK_READ
%token TK_BREAK TK_CONTINUE
%token TK_FOR TK_WHILE TK_DO
%token TK_SWITCH TK_CASE TK_DEFAULT

%start S

%left TK_OR
%left TK_AND
%left TK_IGUALDADE TK_DIFERENTE
%left '<' '>' TK_MENOR_IGUAL TK_MAIOR_IGUAL
%left '+' '-'
%left '*' '/'
%right '!'
%left ':'






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


COMANDO 	: E ';'
			{
				$$ = $1;
			}
			
			| DECLR_TIPO
			{
				$$.traducao = "";
			}
			|CONDICIONAL
			{
				$$.traducao = $1.traducao;
			}
			|IN_OUT
			{
				$$.traducao = $1.traducao;
			}
			
		    |REPETICAO
		    {
		    	$$.traducao = $1.traducao;
		    }
		    | JUMP
		    {
		    	$$.traducao = $1.traducao;
		    }
		    | SWITCH
		    {
		    	$$.traducao = $1.traducao;
		    }
		 	;

CONDICIONAL :TK_IF '(' E ')' BLOCO
			{
			    string lbl = gentempcodeif();
			    $$.traducao = $3.traducao;
			    $$.traducao += "\tif (!" + $3.label + ") goto " + lbl + ";\n";
			    $$.traducao += $5.traducao;
			    $$.traducao += lbl + ":\n";
			}

			| TK_IF '(' E ')' BLOCO TK_ELSE BLOCO
			{
			    string lbl_else = gentempcodeif();
			    string lbl_end = gentempcodeif();
			    $$.traducao = $3.traducao;
			    $$.traducao += "\tif (!" + $3.label + ") goto " + lbl_else + ";\n";
			    $$.traducao += $5.traducao;
			    $$.traducao += "\tgoto " + lbl_end + ";\n";
			    $$.traducao += lbl_else + ":\n";
			    $$.traducao += $7.traducao;
			    $$.traducao += lbl_end + ":\n";
			};

IN_OUT       :TK_PRINT '(' E ')' ';'
		    {
		        if ($3.tipo == "string") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%s\\n\", " + $3.label + ");\n";
		        }
		        else if ($3.tipo == "int") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%d\\n\", " + $3.label + ");\n";
		        }
		        else if ($3.tipo == "float") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%f\\n\", " + $3.label + ");\n";
		        }
		        else if ($3.tipo == "char") {
		            $$.traducao = $3.traducao +
		                          "\tprintf(\"%c\\n\", " + $3.label + ");\n";
		        }
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
		    ;
REPETICAO : TK_FOR '(' ATRIBUICAO ';' RELACIONAL ';' E ')' CONTEXTO_FOR BLOCO
			{
			    string inicio_loop = $9.inicio_loop;
			    string incremento_loop = $9.incremento_loop;
			    string fim_loop = $9.fim_loop;

			    string label_bool = gerarvariavel("bool");
			    adicionar_simbolo(label_bool, label_bool, "bool");

			    simbolo sim_cond = buscar_simbolo_por_interno($5.label);
			    string apelido_cond = sim_cond.nome_interno;

			    $$.traducao =
			        $3.traducao +                    // Inicialização
			        "INICIO_" + inicio_loop + ":\n" +  // Label da condição
			        $5.traducao +                    // Condição
			        "\t" + label_bool + " = !" + apelido_cond + ";\n" +
			        "\tif (" + label_bool + ") goto FIM_" + fim_loop + ";\n" +
			        $10.traducao +                   // Corpo
			        "INCREMENTO_" + incremento_loop + ":\n" + // Label incremento (para continue)
			        $7.traducao +                   // Incremento
			        "\tgoto INICIO_" + inicio_loop + ";\n" +
			        "FIM_" + fim_loop + ":\n";

			    controle_stack.pop_back();
			    loops.pop_back();
			    contador_loop--;
			}
			|TK_WHILE '(' E ')' CONTEXTO_LOOP BLOCO
			{
			    // Pega os labels do CONTEXTO_LOOP (para break/continue)
			    string lbl_inicio = $5.inicio_loop;
			    string lbl_fim    = $5.fim_loop;

			    string label_bool = gerarvariavel("bool");
			    adicionar_simbolo(label_bool, label_bool, "bool");

			    simbolo sim_cond = buscar_simbolo_por_interno($3.label);
			    string apelido_cond = sim_cond.nome_interno;

			    $$.traducao =
			        "INICIO_" + lbl_inicio + ":\n" +    // Label de início (para continue)
			        $3.traducao +                      // Condição
			        "\t" + label_bool + " = !" + apelido_cond + ";\n" + 
			        "\tif (" + label_bool + ") goto FIM_" + lbl_fim + ";\n" +  // Se falso, pula fora
			        $6.traducao +                      // Corpo
			        "\tgoto INICIO_" + lbl_inicio + ";\n" +  // Volta pro começo
			        "FIM_" + lbl_fim + ":\n";          // Label de fim (para break)

			    // Pop do contexto do loop
			    controle_stack.pop_back();
			    loops.pop_back();
			    contador_loop--;
			}
			| TK_DO CONTEXTO_LOOP BLOCO TK_WHILE '(' E ')' ';'
			{
			    string lbl_inicio = $2.inicio_loop;
			    string lbl_fim    = $2.fim_loop;

			    string label_bool = gerarvariavel("bool");
			    adicionar_simbolo(label_bool, label_bool, "bool");

			    simbolo sim_cond = buscar_simbolo_por_interno($6.label);
			    string apelido_cond = sim_cond.nome_interno;

			    $$.traducao =
			        "INICIO_" + lbl_inicio + ":\n" +    // Label de início
			        $3.traducao +                      // Corpo
			        $6.traducao +                      // Condição
			        "\t" + label_bool + " = !" + apelido_cond + ";\n" + 
			        "\tif (!" + label_bool + ") goto INICIO_" + lbl_inicio + ";\n" + // Se verdadeiro, volta
			        "FIM_" + lbl_fim + ":\n";          // Label de fim

			    // Pop do contexto do loop
			    loops.pop_back();
			    controle_stack.pop_back();
			    contador_loop--;
			}
			;


CONTEXTO_FOR:
			{
			    loop ctx = criar_contexto_loop(true); // for tem incremento
			    $$.inicio_loop = ctx.inicio_loop;
			    $$.incremento_loop = ctx.incremento_loop;
			    $$.fim_loop = ctx.fim_loop;
			}
			;


CONTEXTO_LOOP:
			{
			    loop ctx = criar_contexto_loop(false); // while não tem incremento
			    $$.inicio_loop = ctx.inicio_loop;
			    $$.incremento_loop = ctx.incremento_loop;
			    $$.fim_loop = ctx.fim_loop;
			}
			;
CONTEXTO_SWITCH:
			{
			    SwitchContext ctx = criar_contexto_switch();
			}
			;



SWITCH : TK_SWITCH '(' E ')' CONTEXTO_SWITCH BLOCO_SWITCH
			{
			    SwitchContext &ctx = switch_stack.back();

			    string trad_expr = $3.traducao + "\t" + ctx.cond_var + " = " + $3.label + ";\n";

			    $$.traducao = trad_expr + $6.traducao + "FIM_SWITCH_" + ctx.lbl_fim + ":\n";

			    switch_stack.pop_back();
			    controle_stack.pop_back();

			}

CASES : CASE CASES
			{
			    $$.ifs = $1.ifs + $2.ifs;
			    $$.blocks = $1.blocks + $2.blocks;
			    $$.default_block = ""; // default só vem em DEFAULT_CASE
			}
			| /* vazio */
			{
			    $$.ifs = "";
			    $$.blocks = "";
			    $$.default_block = "";
			}
			;

CASE : TK_CASE TK_NUM ':' BLOCO_CASE_SWITCH
			{
			    SwitchContext &ctx = switch_stack.back();
			    string lbl_case = gentempcodeswitch();

			string var_cmp = gerarvariavel("int");
			adicionar_simbolo(var_cmp, var_cmp, "int");

			string cmp_code = "\t" + var_cmp + " = " + ctx.cond_var + " == " + $2.label + ";\n";
			string if_code = "\tif (" + var_cmp + ") goto CASE_" + lbl_case + ";\n";
			string block_code = "CASE_" + lbl_case + ":\n" + $4.traducao;

			$$.ifs = $1.ifs + cmp_code + if_code;
			$$.blocks = $1.blocks + block_code;
			$$.default_block = "";

			}
			;
DEFAULT_CASE : TK_DEFAULT ':' BLOCO_CASE_SWITCH
			{
			    $$.default_block = "DEFAULT:\n" + $3.traducao;
			    $$.ifs = "";
			    $$.blocks = "";
			}
			| /* vazio */
			{
			    $$.ifs = "";
			    $$.blocks = "";
			    $$.default_block = "";
			}
			;
BLOCO_SWITCH : '{'
			{
    		abrir_escopo();
			}
CASES DEFAULT_CASE
			'}'
			{
			    fechar_escopo();
			    string traducao_ifs = $3.ifs;

			    // Se tiver um default definido, forçamos um ELSE GOTO DEFAULT
			    if ($4.default_block != "") {
			        traducao_ifs += "\telse goto DEFAULT;\n";
			    }

			    $$.traducao = traducao_ifs + $3.blocks + $4.default_block;
			}
			;


BLOCO_CASE_SWITCH
		    : /* vazio */ 
		    {
		        abrir_escopo();
		    }
		    COMANDOS
		    {
		        fechar_escopo();
		        $$.traducao = $2.traducao;
		    }
			;

// Regras para JUMP: break e continue
JUMP	 : TK_BREAK ';'
		    {
		        if (!controle_stack.empty()) {
		            ContextoControle &ctx = controle_stack.back();
		            if (ctx.tipo == CONTEXTO_SWITCH) {
		                $$.traducao = "\tgoto FIM_SWITCH_" + ctx.lbl_fim + ";\n";
		            } else if (ctx.tipo == CONTEXTO_LOOP) {
		                $$.traducao = "\tgoto FIM_" + ctx.lbl_fim + ";\n";
		            }
		        } else {
		            yyerror("/* ERRO: break fora de loop ou switch */\n");
		        }
		    }
    | TK_CONTINUE ';'
    	{
     		if (!controle_stack.empty()) {
			    ContextoControle &ctx = controle_stack.back();
			    if (ctx.tipo == CONTEXTO_LOOP) {
			        string destino_continue;

			        if (ctx.lbl_incremento != "") {
			            destino_continue = "INCREMENTO_" + ctx.lbl_incremento;
			        } else {
			            destino_continue = "INICIO_" + ctx.lbl_inicio;
			        }
			        $$.traducao = "\tgoto " + destino_continue + ";\n";
			    } else {
			        yyerror("DEBUG: continue fora de loop detectado\n");
			        $$.traducao = "/* ERRO: continue fora de loop */\n";
			    }
			} else {
			    yyerror("/* ERRO: continue fora de loop */\n");
			}

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
			| ATRIBUICAO
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

ATRIBUICAO	: TK_ID '=' E
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


string gentempcodeloop() {
    return "L" + to_string(contador_label_loop++);
}

string gentempcodeswitch() {
    return "SWITCH" + to_string(contador_label_switch++);
}

string gentempcodeif(){
	var_if_qnt++;
	string var = "C" + to_string(var_if_qnt);
	return var;
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


loop criar_contexto_loop(bool tem_incremento) {
    loop ctx;
    ctx.inicio_loop = gentempcodeloop();
    ctx.incremento_loop = tem_incremento ? gentempcodeloop() : "";
    ctx.fim_loop = gentempcodeloop();

    adicionar_simbolo(ctx.inicio_loop, ctx.inicio_loop, "label");
    if (tem_incremento)
        adicionar_simbolo(ctx.incremento_loop, ctx.incremento_loop, "label");
    adicionar_simbolo(ctx.fim_loop, ctx.fim_loop, "label");

    // Atualiza controle_stack
    ContextoControle ctrl_ctx;
    ctrl_ctx.tipo = CONTEXTO_LOOP;
    ctrl_ctx.lbl_fim = ctx.fim_loop;
    ctrl_ctx.lbl_incremento = ctx.incremento_loop;
    ctrl_ctx.lbl_inicio = ctx.inicio_loop;  // útil em while/do-while
    controle_stack.push_back(ctrl_ctx);

    loops.push_back(ctx);
    contador_loop++;

    return ctx;
}

switchcase criar_contexto_switch() {
    SwitchContext ctx;
    ctx.lbl_fim = gentempcodeswitch();
    ctx.cond_var = gerarvariavel("int");

    adicionar_simbolo(ctx.cond_var, ctx.cond_var, "int");

    // Controle para break funcionar dentro do switch
    ContextoControle ctrl_ctx;
    ctrl_ctx.tipo = CONTEXTO_SWITCH;
    ctrl_ctx.lbl_fim = ctx.lbl_fim;
    ctrl_ctx.lbl_incremento = "";  // switch não tem incremento
    controle_stack.push_back(ctrl_ctx);

    switch_stack.push_back(ctx);

    return ctx;
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