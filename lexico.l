%option yylineno

%{
#include "y.tab.h"
#include <stdio.h>
#include <string.h>
extern FILE *log_tokens; 
void registrar_token(const char* texto, const char* significado){
    if(log_tokens != NULL){
        fprintf(log_tokens, "%s -> %s\n", texto, significado);
    }
}
/*função pra tratar virgula, somente virgula diaxo de virgula */
double trata_virgula_atof(const char* str){
    char buffer[256];
    
    strncpy(buffer, str, sizeof(buffer) - 1);
    buffer[sizeof(buffer) - 1] = '\0'; 
    
    for(int i = 0; buffer[i] != '\0'; i++){
        if(buffer[i] == ','){
            buffer[i] = '.';
            break;
        }
    }
    
    return atof(buffer);
}

%}
extern void yyerror(const char *s);
/*definições de padrões Tabela 3 do relatório */
letra     [a-zA-Z]
num       [0-9]
id        {letra}({letra}|{num}|_)*
numero    [+-]?{num}+(,{num}+)?

%%

"$"[^\n]*    {/*Ignora comentários de linha*/}
[ \t\n\r]+   {/*Ignora espaços em branco*/}

    /*bloco e Instrução*/
"abre_buteco"|"abre_o_buteco"     {registrar_token(yytext, "abre chaves"); return T_ABREBUTECO;}
"fecha_buteco"|"fecha_o_buteco"   {registrar_token(yytext, "fecha chaves"); return T_FECHABUTECO;}
"desce"                           {registrar_token(yytext, "fim de instrucao"); return T_DEL;}
    /*palavras Reservadas Tipos de Dados*/
"dose"                            {registrar_token(yytext, "palavra reservada (tipo inteiro)"); return T_DOSE;}
"litrao"                          {registrar_token(yytext, "palavra reservada (tipo float)"); return T_LITRAO;}
"petisco"                         {registrar_token(yytext, "palavra reservada (tipo char)"); return T_PETISCO;}
"ressaca"                         {registrar_token(yytext, "palavra reservada (tipo void)"); return T_RESSACA;}
"copo_vazio"                      {registrar_token(yytext, "palavra reservada (tipo null)"); return T_COPOVAZIO;}
    /*palavras Reservadas: Controle de Fluxo*/
"se_ta_pago"                      {registrar_token(yytext, "comando condicional"); return T_SETAPAGO;}
"se_nao"                          {registrar_token(yytext, "sentença alternativa"); return T_SENAO;}
"rodada"                          {registrar_token(yytext, "laço de repetição"); return T_RODADA;}
"enche_o_copo"                    {registrar_token(yytext, "laço de repetição"); return T_ENCHE;}
"cardapio"                        {registrar_token(yytext, "estrutura de selecao"); return T_CARDAPIO;}
"pedido"                          {registrar_token(yytext, "opção do cardápio"); return T_PEDIDO;}
"lei seca"|"lei_seca"             {registrar_token(yytext, "comando de parar"); return T_LEISECA;}
    /*palavras Reservadas: Comandos e Modificadores*/
"pede_pro_garcom"                 {registrar_token(yytext, "comando de entrada"); return T_PEDEGARCOM;}
"chama_truco"                     {registrar_token(yytext, "comando de saida"); return T_CHAMATRUCO;}
"saidera"                         {registrar_token(yytext, "retorno de função"); return T_SAIDERA;}
"apelidar"                        {registrar_token(yytext, "palavra reservada"); return T_APELIDAR;}
"desce_uma"                       {registrar_token(yytext, "palavra reservada"); return T_DESCEUMA;}
"racha"                           {registrar_token(yytext, "operador de distribuicao"); return T_RACHA;}
"pre_pago"                        {registrar_token(yytext, "palavra reservada (modificador de tipo)"); return T_PREPAGO;}
    /*valores Booleanos*/
"ta_pago"                         {registrar_token(yytext, "booleano verdadeiro"); return T_TAPAGO;}
"ta_pendurado"                    {registrar_token(yytext, "booleano falso"); return T_TAPENDURADO;}
    /*operadores de Atribuição e Relacionais*/
"anota"                           {registrar_token(yytext, "atribuicao"); return T_ANOTA;}
"bate_com"                        {registrar_token(yytext, "operador relacional (igualdade)"); return T_BATECOM;}
"nao_bate"                        {registrar_token(yytext, "operador relacional (desigualdade)"); return T_NAOBATE;}
">="                              {registrar_token(yytext, "operador relacional (maior ou igual)"); return T_GEQ;}
"<="                              {registrar_token(yytext, "operador relacional (menor ou igual)"); return T_LEQ;}
">"                               {registrar_token(yytext, "operador relacional (maior)"); return T_GT;}
"<"                               {registrar_token(yytext, "operador relacional (menor)"); return T_LT;}
    /*operadores Lógicos*/
"e"                               {registrar_token(yytext, "operador logico (AND)"); return T_E;}
"ou"                              {registrar_token(yytext, "operador logico (OR)"); return T_OU;}
"nao"                             {registrar_token(yytext, "operador logico (NOT)"); return T_NAO;}
    /*operadores Aritméticos*/
"+"                               {registrar_token(yytext, "operador aritmetico (soma)"); return T_PLUS;}
"-"                               {registrar_token(yytext, "operador aritmetico (subtracao)"); return T_MINUS;}
"*"                               {registrar_token(yytext, "operador aritmetico (multiplicacao)"); return T_MUL;}
"/"                               {registrar_token(yytext, "operador aritmetico (divisao)"); return T_DIV;}
"mod"                             {registrar_token(yytext, "operador aritmetico (modulo)"); return T_MOD;}
    /*símbolos Especiais e Pontuação*/
";"                               {registrar_token(yytext, "separador"); return T_COMMA;}
":"                               {registrar_token(yytext, "dois pontos"); return T_COLON;}
"("                               {registrar_token(yytext, "abre parenteses"); return T_LPAREN;}
")"                               {registrar_token(yytext, "fecha parenteses"); return T_RPAREN;}
    /*literais de Strings*/
\"[^\"]*\"                        {registrar_token(yytext, "literal de string"); strcpy(yylval.str_val, yytext); return T_STR;}
    /*identificadores e Números */
{id}                              {registrar_token(yytext, "identificador"); strcpy(yylval.nome_id, yytext); /*salva o nome da variável para o Bison*/ return T_ID; }
{numero}                          {registrar_token(yytext, "número"); yylval.valor_num = trata_virgula_atof(yytext); return T_NUM;}
.                                 {printf("Erro léxico: Caractere inválido no bar na linha %d: '%s'\n", yylineno, yytext);}
%%
int yywrap(){
    return 1;
}