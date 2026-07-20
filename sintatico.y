%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

extern int yylex();
extern char* yytext;
extern int yylineno;
void yyerror(const char *s);
extern FILE *log_tokens;

//TABELA DE SÍMBOLOS (Memória) 
char nomes_vars[100][50];
double valores_vars[100];
int eh_prepago[100];
int total_vars = 0;

int obter_indice_var(char *nome){
    for(int i = 0; i < total_vars; i++){
        if(strcmp(nomes_vars[i], nome) == 0) return i;
    }
    strcpy(nomes_vars[total_vars], nome);
    valores_vars[total_vars] = 0.0;
    total_vars++;
    return total_vars - 1;
}

void marcar_como_prepago(char *nome){
    int indice = obter_indice_var(nome);
    eh_prepago[indice] = 1;
}

void imprime_num(double valor){
    char buffer[50];
    sprintf(buffer, "%.2f", valor); // formata com 2 casas decimais
    
    // troca o ponto pela vírgula
    for(int i = 0; buffer[i] != '\0'; i++){
        if(buffer[i] == '.'){
            buffer[i] = ',';
            break;
        }
    }
    printf("%s", buffer);
}

//ESTRUTURAS DA ÁRVORE SINTÁTICA (AST) 
typedef enum{
    NODE_NUM, NODE_ID, NODE_STR, NODE_OP_BINARIA, NODE_ATRIBUICAO,
    NODE_TRUCO, NODE_ESCUTA, NODE_SE, NODE_ENQUANTO, NODE_RODADA, 
    NODE_CARDAPIO, NODE_PEDIDO, NODE_RETORNO, NODE_SEQ, NODE_RACHA
} NodeType;

typedef struct ASTNode{
    NodeType tipo;
    double valor;           
    char id[50];
    char str_val[200]; //para armazenar Strings 
    int operador;           
    struct ASTNode *esq;    
    struct ASTNode *dir;    
    struct ASTNode *cond;   
    struct ASTNode *corpo;  
    struct ASTNode *senao;  
    struct ASTNode *proximo;
    char lista_ids[10][50]; 
    int qtd_ids;            
}ASTNode;

// construtores dos Nós da Árvore 
ASTNode* novo_no_num(double val){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_NUM; no->valor = val; return no;
}
ASTNode* novo_no_str(char* texto){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_STR; strcpy(no->str_val, texto); return no;
}
ASTNode* novo_no_id(char* nome){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_ID; strcpy(no->id, nome); return no;
}
ASTNode* novo_no_op(int op, ASTNode* esq, ASTNode* dir){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_OP_BINARIA; no->operador = op;
    no->esq = esq; no->dir = dir; return no;
}
ASTNode* novo_no_atribuicao(char* nome, ASTNode* dir){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_ATRIBUICAO; strcpy(no->id, nome); no->dir = dir; return no;
}
ASTNode* novo_no_escuta(char* id){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_ESCUTA; strcpy(no->id, id); return no;
}
ASTNode* novo_no_truco(ASTNode* dir){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_TRUCO; no->dir = dir; return no;
}
ASTNode* novo_no_se(ASTNode* cond, ASTNode* corpo, ASTNode* senao){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_SE; no->cond = cond; no->corpo = corpo; no->senao = senao; return no;
}
ASTNode* novo_no_enquanto(ASTNode* cond, ASTNode* corpo){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_ENQUANTO; no->cond = cond; no->corpo = corpo; return no;
}
ASTNode* novo_no_rodada(ASTNode* init, ASTNode* cond, ASTNode* passo, ASTNode* corpo){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_RODADA; no->esq = init; no->cond = cond; no->dir = passo; no->corpo = corpo; return no;
}
ASTNode* novo_no_cardapio(char* id, ASTNode* casos){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_CARDAPIO; strcpy(no->id, id); no->esq = casos; return no;
}
ASTNode* novo_no_pedido(ASTNode* valor, ASTNode* corpo){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_PEDIDO; no->cond = valor; no->corpo = corpo; return no;
}
ASTNode* novo_no_retorno(ASTNode* exp){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_RETORNO; no->dir = exp; return no;
}
ASTNode* novo_no_seq(ASTNode* cmd1, ASTNode* cmd2){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_SEQ; no->esq = cmd1; no->proximo = cmd2; return no;
}
ASTNode* novo_no_racha(char ids[10][50], int qtd, ASTNode* dir){
    ASTNode* no = (ASTNode*)malloc(sizeof(ASTNode));
    no->tipo = NODE_RACHA; no->qtd_ids = qtd; no->dir = dir;
    for(int i = 0; i < qtd; i++) strcpy(no->lista_ids[i], ids[i]);
    return no;
}
double executar_arvore(ASTNode* no){
    if (no == NULL) return 0;
    
    switch (no->tipo){
        case NODE_NUM: return no->valor;
        case NODE_STR: return 0; // strings sao tratadas direto no TRUCO 
        case NODE_ID: return valores_vars[obter_indice_var(no->id)];
        case NODE_SEQ:
            executar_arvore(no->esq);
            executar_arvore(no->proximo);
            return 0;
        case NODE_ATRIBUICAO:{
            double val = executar_arvore(no->dir);
            int idx = obter_indice_var(no->id);

            if (eh_prepago[idx] && val < 0){
                printf("[Garçom] Conta '%s' eh pre-paga e esgotou o saldo! Travando em 0,00.\n", no->id);
                val = 0;
            }

            valores_vars[idx] = val;
            return val;
        }
        case NODE_RACHA:{
            double total = executar_arvore(no->dir);
            double fatia = total / no->qtd_ids;
            for(int i = 0; i < no->qtd_ids; i++){
                valores_vars[obter_indice_var(no->lista_ids[i])] = fatia;
            }
            return total;
        }
        case NODE_ESCUTA:{
            double entrada;
            printf("[Cliente] O cliente dita o valor para '%s': ", no->id);
            if (scanf("%lf", &entrada) != 1) entrada = 0;
            int c;
            while ((c = getchar()) != '\n' && c != EOF){} // limpa o buffer do teclado
            valores_vars[obter_indice_var(no->id)] = entrada;
            return entrada;
        }
        case NODE_TRUCO:{
            if(no->dir->tipo == NODE_STR){
                //remove as aspas na hora de imprimir 
                char tmp[200];
                strcpy(tmp, no->dir->str_val);
                if(tmp[0] == '"') tmp[strlen(tmp)-1] = '\0';
                printf(">> MESA PEDIU TRUCO! Mensagem: %s\n", tmp[0] == '"' ? tmp+1 : tmp);
            } else{
                //printf(">> MESA PEDIU TRUCO! Valor: %.2f\n", executar_arvore(no->dir));
                printf(">> MESA PEDIU TRUCO! Valor: ");
                imprime_num(executar_arvore(no->dir));
                printf("\n");
            }
            return 0;
        }
        case NODE_SE:{
            if (executar_arvore(no->cond) != 0) executar_arvore(no->corpo);
            else if (no->senao != NULL) executar_arvore(no->senao);
            return 0;
        }
        case NODE_ENQUANTO:{
            while (executar_arvore(no->cond) != 0) executar_arvore(no->corpo);
            return 0;
        }
        case NODE_RODADA:{
            //laco FOR: Roda a atribuicao inicial, avalia condicao, executa corpo e roda o passo 
            for(executar_arvore(no->esq); executar_arvore(no->cond) != 0; executar_arvore(no->dir)){
                executar_arvore(no->corpo);}
            return 0;
        }
        case NODE_CARDAPIO:{
            // estrutura Switch/Case 
            double var_val = valores_vars[obter_indice_var(no->id)];
            ASTNode* p = no->esq;
            while(p){
                if(p->tipo == NODE_SEQ){ 
                    ASTNode* item = p->esq;
                    if(item && item->tipo == NODE_PEDIDO && executar_arvore(item->cond) == var_val){
                        executar_arvore(item->corpo); break;
                    }
                    p = p->proximo;
                } else if(p->tipo == NODE_PEDIDO){
                    if(executar_arvore(p->cond) == var_val){ executar_arvore(p->corpo); break;}
                    break;
                }
            }
            return 0;
        }
        case NODE_RETORNO:{
            double val = executar_arvore(no->dir);
            // printf("[Garçom] Saidera! Conta fechada no valor de: %.2f\n", val);
            printf("[Garçom] Saidera! Conta fechada no valor de: ");
            imprime_num(val);
            printf("\n");
            exit(0);
        }
        case NODE_OP_BINARIA:{
            double esq = executar_arvore(no->esq);
            double dir = executar_arvore(no->dir);
            switch (no->operador){
                case '+': return esq + dir;
                case '-': return esq - dir;
                case '*': return esq * dir;
                case '/': return dir == 0 ? 0 : esq / dir;
                case '%': return fmod(esq, dir);
                case '>': return esq > dir;
                case '<': return esq < dir;
                case 1: return esq == dir; // BATECOM 
                case 2: return esq != dir; // NAOBATE 
                case 3: return esq >= dir; // GEQ 
                case 4: return esq <= dir; // LEQ 
                case '&': return esq && dir; // Operador E 
                case '|': return esq || dir; // Operador OU 
            }
        }
    }
    return 0;
}

void liberar_arvore(ASTNode* no){

    if (no == NULL) return;

    liberar_arvore(no->esq);
    liberar_arvore(no->dir);
    liberar_arvore(no->cond);
    liberar_arvore(no->corpo);
    liberar_arvore(no->senao);
    liberar_arvore(no->proximo);

    free(no);
}

%}

//tipos de dados na árvore 
%union{
    double valor_num;
    char nome_id[50];
    char str_val[200];
    struct ASTNode* no_ast;
    struct{
        char nomes[10][50];
        int qtd;
    }lista_nomes;
}
//conexão dos tokens com a AST 
%token <valor_num> T_NUM
%token <nome_id> T_ID
%token <str_val> T_STR
%type <no_ast> Bloco ListaComandos Comando Atribuicao Truco Condicional OptElse Enquanto Condicao ExprRelacional ExprAritmetica Termo Fator Rachadinha Escuta Retorno DeclaraVar Para_Rodada Escolha_Cardapio ListaPedidos PedidoItem AlgebraBooleana DesceUma Apelidar
%type <valor_num> relacional
%type <lista_nomes> ListalDs ListaIdAnota
%token T_ABREBUTECO T_FECHABUTECO T_DEL
%token T_DOSE T_LITRAO T_PETISCO T_RESSACA T_COPOVAZIO
%token T_SETAPAGO T_SENAO T_RODADA T_ENCHE T_CARDAPIO T_PEDIDO T_LEISECA
%token T_PEDEGARCOM T_CHAMATRUCO T_SAIDERA T_APELIDAR T_DESCEUMA
%token T_RACHA T_PREPAGO T_TAPAGO T_TAPENDURADO
%token T_ANOTA T_BATECOM T_NAOBATE T_GEQ T_LEQ T_GT T_LT
%token T_E T_OU T_NAO
%token T_PLUS T_MINUS T_MUL T_DIV T_MOD
%token T_COMMA T_COLON T_LPAREN T_RPAREN

%%

Programa:
    T_ABREBUTECO Bloco T_FECHABUTECO{ 
        //printf("\n[Garcom] Pedido anotado! Executando a arvore sintatica...\n\n"); 
        executar_arvore($2);
        liberar_arvore($2);
    }
    ;

Bloco:
    ListaComandos{ $$ = $1;}
    | { $$ = NULL;}
    ;

ListaComandos:
    Comando ListaComandos{ $$ = novo_no_seq($1, $2); }
    | Comando{ $$ = $1; }
    ;

Comando:
    DeclaraVar{ $$ = $1;}
    | Atribuicao{$$ = $1;}
    | Rachadinha{$$ = $1;}
    | Escuta{$$ = $1;}
    | Truco{$$ = $1;}
    | Condicional{$$ = $1;}
    | Enquanto{$$ = $1;}
    | Para_Rodada{$$ = $1;}
    | Escolha_Cardapio{$$ = $1;}
    | Retorno{$$ = $1;}
    | DesceUma{$$ = $1;}
    | Apelidar{$$ = $1;}
    ;
//declaração Formal de Variáveis 
DeclaraVar:
    Tipos T_ID T_DEL {$$ = novo_no_atribuicao($2, novo_no_num(0));}
    | Tipos T_ID ListaIdAnota T_ANOTA ExprAritmetica T_DEL{$$ = novo_no_atribuicao($2, $5);}
    | T_PREPAGO Tipos T_ID T_DEL{
        marcar_como_prepago($3); // Avisa a memória que essa mesa é pré-paga 
        $$ = novo_no_atribuicao($3, novo_no_num(0));
    }
    ;
ListaIdAnota:
    ListaIdAnota T_ANOTA T_ID{$$ = $1;}
    | {$$.qtd = 0;}
    ;

Tipos: T_DOSE | T_LITRAO | T_PETISCO | T_RESSACA | T_COPOVAZIO ;

Atribuicao:
    T_ID T_ANOTA ExprAritmetica T_DEL{$$ = novo_no_atribuicao($1, $3);}
    ;
Rachadinha:
    ListalDs T_RACHA ExprAritmetica T_DEL{$$ = novo_no_racha($1.nomes, $1.qtd, $3);}
    ;
ListalDs:
    T_ID {$$.qtd = 1; strcpy($$.nomes[0], $1);}
    | ListalDs T_COMMA T_ID{$$ = $1; strcpy($$.nomes[$$.qtd], $3); $$.qtd++;}
    ;
Escuta:
    T_PEDEGARCOM T_LPAREN T_ID T_RPAREN T_DEL{$$ = novo_no_escuta($3);}
    ;
Truco:
    T_CHAMATRUCO T_LPAREN ExprAritmetica T_RPAREN T_DEL{$$ = novo_no_truco($3);}
    | T_CHAMATRUCO T_LPAREN T_STR T_RPAREN T_DEL{$$ = novo_no_truco(novo_no_str($3));}
    ;
Condicional:
    T_SETAPAGO T_LPAREN Condicao T_RPAREN T_ABREBUTECO Bloco T_FECHABUTECO OptElse 
    {$$ = novo_no_se($3, $6, $8);}
    ;
OptElse:
    T_SENAO T_ABREBUTECO Bloco T_FECHABUTECO{ $$ = $3;}
    | {$$ = NULL;}
    ;
Enquanto:
    T_ENCHE T_LPAREN Condicao T_RPAREN T_ABREBUTECO Bloco T_FECHABUTECO 
    {$$ = novo_no_enquanto($3, $6);}
    ;
Para_Rodada:
    T_RODADA T_LPAREN Atribuicao Condicao T_DEL Atribuicao T_RPAREN T_ABREBUTECO Bloco T_FECHABUTECO
    {$$ = novo_no_rodada($3, $4, $6, $9);}
    ;
Escolha_Cardapio:
    T_CARDAPIO T_LPAREN T_ID T_RPAREN T_ABREBUTECO ListaPedidos T_FECHABUTECO
    {$$ = novo_no_cardapio($3, $6);}
    ;
ListaPedidos:
    ListaPedidos PedidoItem{ $$ = novo_no_seq($1, $2);}
    | PedidoItem{$$ = $1;}
    ;
PedidoItem:
    T_PEDIDO Fator T_COLON Bloco T_LEISECA T_DEL{$$ = novo_no_pedido($2, $4);}
    ;
Retorno:
    T_SAIDERA T_LPAREN ExprAritmetica T_RPAREN T_DEL{$$ = novo_no_retorno($3);}
    ;

Condicao:
    AlgebraBooleana{$$ = $1;}
    | T_NAO AlgebraBooleana{$$ = $2; /*Simplificado na AST*/}
    ;
AlgebraBooleana:
    ExprRelacional{$$ = $1;}
    | AlgebraBooleana T_E ExprRelacional{$$ = novo_no_op('&', $1, $3);}
    | AlgebraBooleana T_OU ExprRelacional{$$ = novo_no_op('|', $1, $3);}
    ;
ExprRelacional:
    ExprAritmetica relacional ExprAritmetica{$$ = novo_no_op($2, $1, $3);}
    ;
relacional:
    T_BATECOM   {$$ = 1;}
    | T_NAOBATE {$$ = 2;}
    | T_GEQ     {$$ = 3;}
    | T_LEQ     {$$ = 4;}
    | T_GT      {$$ = '>';}
    | T_LT      {$$ = '<';}
    ;
ExprAritmetica:
    Termo {$$ = $1;}
    | ExprAritmetica T_PLUS Termo  {$$ = novo_no_op('+', $1, $3);}
    | ExprAritmetica T_MINUS Termo {$$ = novo_no_op('-', $1, $3);}
    ;
Termo:
    Fator {$$ = $1; }
    | Termo T_MUL Fator{$$ = novo_no_op('*', $1, $3);}
    | Termo T_DIV Fator{$$ = novo_no_op('/', $1, $3);}
    | Termo T_MOD Fator{$$ = novo_no_op('%', $1, $3);}
    ;
Fator:
    T_NUM {$$ = novo_no_num($1);}
    | T_ID{$$ = novo_no_id($1);}
    | T_LPAREN ExprAritmetica T_RPAREN{$$ = $2;}
    | T_TAPAGO{$$ = novo_no_num(1);}
    | T_TAPENDURADO{$$ = novo_no_num(0);}
    ;
DesceUma:
    T_DESCEUMA T_ID T_DEL{ 
        $$ = novo_no_atribuicao($2, novo_no_op('+', novo_no_id($2), novo_no_num(1))); 
    }
    ;
Apelidar:
    T_APELIDAR T_ID T_ID T_DEL{ 
        $$ = novo_no_atribuicao($2, novo_no_id($3)); 
    }
    ;

%%

void yyerror(const char *s){
    fprintf(stderr, "[Erro Sintático] O garçom não entendeu o pedido na linha %d perto de '%s': %s\n", yylineno, yytext, s);
}

FILE *log_tokens;
extern FILE *yyin; // diz ao Flex que vamos mudar a fonte de leitura 

int main(int argc, char **argv){
    log_tokens = fopen("tokens_reconhecidos.txt", "w");
    if(!log_tokens){
        printf("Erro ao criar arquivo de log de tokens!\n");
        return 1;
    }
    // se o usuario passou um arquivo na linha de comando, abrimos ele 
    if (argc > 1){
        yyin = fopen(argv[1], "r");
        if (!yyin){
            printf("Erro: O garçom não encontrou o arquivo '%s'\n", argv[1]);
            return 1;
        }
    }
    printf("--- Compilador buteCo Aberto ---\n");
    yyparse();
    fclose(log_tokens);
    if(yyin) fclose(yyin);
    return 0;
}