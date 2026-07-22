# Compilador buteCo 🍻

O **buteCo** é uma linguagem de programação esotérica e um compilador temático inspirado na cultura de boteco brasileira. Desenvolvido com **Flex** para a análise léxica e **Bison** para a análise sintática, o compilador lê arquivos `.btc`, monta uma Árvore Sintática Abstrata (AST) e executa o programa diretamente no terminal.

---

## Pré-requisitos

Para compilar e executar o projeto, você precisa ter instalados:

- **Flex**
- **Bison**
- **GCC**

### Linux (Ubuntu/Debian) e Windows via WSL

A forma mais simples de usar as ferramentas no Windows é por meio do **WSL** (Windows Subsystem for Linux). No terminal do Linux ou do WSL, execute:

```bash
sudo apt update
sudo apt install flex bison gcc make
```

### Windows nativo

Se preferir não usar o WSL, você pode instalar as dependências com **Chocolatey** ou **MSYS2**.

```powershell
choco install winflexbison mingw
            ou
winget install -e --id WinFlexBison.win_flex_bison
```

Observação: no Windows nativo, os nomes e caminhos dos binários podem variar, e o executável final tende a ser gerado como `compilador_buteco.exe`.

---

## Como compilar

Com as dependências instaladas, abra o terminal na pasta do projeto, onde estão `lexico.l` e `sintatico.y`.

Execute os comandos nesta ordem:

*Para linux:*
```bash
bison -dy sintatico.y
flex lexico.l
```

*Para Windows:*
```bash
win_bison -dy sintatico.y
win_flex lexico.l
```

*Compilando em ambos:*
```bash
gcc lex.yy.c y.tab.c -o compilador_buteco
```

Observação: O comando do **Bison** gera `y.tab.c` e `y.tab.h`, e o comando do **Flex** gera `lex.yy.c`.

Se o seu ambiente acusar erro de linkedição relacionado a `fmod`, adicione `-lm` ao final do comando do GCC.

---

## Como executar os exemplos

Depois da compilação, o executável `compilador_buteco` será criado na pasta.

Para rodar os arquivos de exemplo `.btc`, passe o arquivo como argumento:

```bash
# Exemplo da divisão da conta
./compilador_buteco ex1.btc

# Exemplo da estrutura de cardápio
./compilador_buteco ex2.btc

# Exemplo com a sequência de Fibonacci
./compilador_buteco exFibo.btc
```

---

## Logs de execução

Sempre que um programa válido é executado, o analisador léxico registra os tokens lidos e seus significados.

Ao final da execução, verifique o arquivo gerado automaticamente:

```text
tokens_reconhecidos.txt
```

---

## Visão geral da gramática

Para referência rápida, algumas das palavras reservadas e estruturas reconhecidas pela gramática do buteCo são:

- Bloco principal: `abre_buteco` ... `fecha_buteco`
- Fim de instrução: `desce` (equivalente ao `;`)
- Tipos de variáveis: `dose` (`int`), `litrao` (`float`), `petisco` (`char`)
- Entrada e saída: `pede_pro_garcom()` e `chama_truco()`
- Condicionais e laços: `se_ta_pago` (`if`), `se_nao` (`else`), `enche_o_copo` (`while`), `rodada` (`for`)
