# ⚙️ Compilador Vasco

> Um compilador desenvolvido como parte da disciplina de Compiladores na **Universidade Federal Rural do Rio de Janeiro (UFRRJ)**.

O **Vasco** é um compilador educacional criado com foco no aprendizado de técnicas de análise léxica, sintática e geração de código intermediário utilizando **Flex** e **Bison**. Ele interpreta arquivos com a extensão `.foca`, validando e processando a linguagem definida no projeto.

---

## 🚀 Funcionalidades

- ✅ Análise léxica com Flex (`lexico.l`)
- ✅ Análise sintática com Bison (`sintatico.y`)
- ✅ Execução automatizada com Makefile
- ✅ Suporte à definição e uso de funções
- ✅ Reconhecimento de estruturas condicionais como `if`
- ✅ Saída e compilação final automatizada

---

## 🔧 Instalação

Você precisará das ferramentas:

- `flex`
- `bison`
- `g++`

### Ubuntu

bash
sudo apt install build-essential flex bison

▶️ Execução
Foi criado um Makefile com os comandos necessários para compilar o projeto.

Passos:

Compile o projeto:

make

O script executará a análise do arquivo exemplo.foca automaticamente.

📁 Estrutura do Projeto

compilador/
├── lexico.l          # Regras de análise léxica
├── sintatico.y       # Regras de análise sintática
├── exemplo.foca      # Código de teste na linguagem
├── Makefile          # Script de build automatizado
├── LICENSE           # Licença MIT
└── README.md         # Documentação


👨‍💻 Autor
Pedro Nunes
Desenvolvido como parte da disciplina de Compiladores - UFRRJ
Contribuições e sugestões são sempre bem-vindas!
