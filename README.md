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

Você precisará das seguintes ferramentas:

- `flex`
- `bison`
- `g++`

### Ubuntu

Execute o comando abaixo para instalar as dependências:

```bash
sudo apt install build-essential flex bison

👨‍💻 Autor
Pedro Nunes
Desenvolvido como parte da disciplina de Compiladores – UFRRJ
Contribuições e sugestões são sempre bem-vindas!

yaml
Copiar
Editar
