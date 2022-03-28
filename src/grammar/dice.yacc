/* Defines */
%code requires{
    #include "shared_header.h"
    #include "vector_functions.h"
}
/* %error-verbose  - Deprecated + not supported by POSIX*/
%define parse.error verbose
/* %error-verbose */
%{

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <stdbool.h>
#include "yacc_header.h"
#include "vector_functions.h"
#include "shared_header.h"

int yylex(void);
int yyerror(const char* s);

int yydebug=1;
// random_mock_count is used only for testing
int random_mock_count=0;

int initialize(){
    srand(time(NULL));
}

int collapse(int * arr, int len){
    return sum(arr, len);
}

int sum(int * arr, int len){
    int result = 0;
    for(int i = 0; i != len; i++) result += arr[i];
    return result;
}

int roll_numeric_die(int small, int big){
    // Returns random value between small and big
    return rand()%(big+1-small)+small;
}
int roll_symbolic_die(int length_of_symbolic_array){
    // Returns random index into symbolic array
    return rand()%(length_of_symbolic_array);
}

%}


%start dice

%token NUMBER SIDED_DIE FATE_DIE REPEAT PENETRATE MACRO_ACCESSOR MACRO_STORAGE
%token DIE
%token KEEP_LOWEST KEEP_HIGHEST
%token LBRACE RBRACE PLUS MINUS MULT MODULO DIVIDE_ROUND_UP DIVIDE_ROUND_DOWN

/* Defines Precedence from Lowest to Highest */
%left PLUS MINUS
%left MULT DIVIDE_ROUND_DOWN DIVIDE_ROUND_UP MODULO
%left KEEP_LOWEST KEEP_HIGHEST
%left UMINUS
%left LBRACE RBRACE
/* %left DIE SIDED_DIE FATE_DIE
%left NUMBER */




%union{
    vec values;
}
/* %type<die> DIE; */
%type<values> NUMBER;

%%
/* Rules Section */

dice: collapse{
    vec vector;
    vector = $<values>1;

    for(int i = 0; i!= vector.length;i++){
        if (vector.dtype == SYMBOLIC){
            printf("%c\n", vector.symbols[i][0]);
        }else{
            // TODO: Strings >1 character
            printf("%d\n", vector.content[i]);
        }
    }
}

collapse: math{
    vec vector;
    vector = $<values>1;

    if (vector.dtype == SYMBOLIC){
        $<values>$ = vector;
    }else{
        int c;
        for(int i = 0; i != vector.length; i++){
            c += vector.content[i];
        }
        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.content[0] = c;
        new_vec.length = 1;
        new_vec.dtype = vector.dtype;
        $<values>$ = new_vec;
    }
}
math:
    LBRACE math RBRACE{
        $<values>$ =  $<values>2;
    }
    |
    math MULT math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = v1 * v2;

        $<values>$ = new_vec;
    }
    |
    math DIVIDE_ROUND_UP math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = (v1+(v2-1))/ v2;

        $<values>$ = new_vec;
    }
    |
    math DIVIDE_ROUND_DOWN math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = v1 / v2;

        $<values>$ = new_vec;
    }
    |
    math MODULO math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = v1 % v2;

        $<values>$ = new_vec;
    }
    |
    math PLUS math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = v1 + v2;

        $<values>$ = new_vec;
    }
    |
    math MINUS math{
        // Collapse both sides and subtract
        vec vector1;
        vec vector2;

        vector1 = $<values>1;
        vector2 = $<values>3;
        int v1 = collapse(vector1.content, vector1.length);
        int v2 = collapse(vector2.content, vector2.length);

        vec new_vec;
        new_vec.content = malloc(sizeof(int));
        new_vec.length = 1;
        new_vec.content[0] = v1 - v2;

        $<values>$ = new_vec;
    }
    |
    MINUS math %prec UMINUS{
        // Eltwise Negation
        vec vector;
        vec new_vec;

        vector = $<values>2;

        new_vec.content = malloc(sizeof(int)*vector.length);
        new_vec.length = vector.length;

        for(int i = 0; i != vector.length; i++){
            new_vec.content[i] = - vector.content[i];
        }
        $<values>$ = new_vec;
    }
    |
    drop_keep
;


drop_keep:
    die_roll KEEP_HIGHEST NUMBER
    {
        vec roll_vector, keep_vector;
        roll_vector = $<values>1;
        keep_vector = $<values>3;

        if (roll_vector.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        // assert $0 is len 1
        int available_amount =roll_vector.length;
        int amount_to_keep = keep_vector.content[0];

        if(available_amount > amount_to_keep){
            vec new_vector;
            new_vector.content = malloc(sizeof(int)*amount_to_keep);
            new_vector.length = amount_to_keep;

            int * arr = roll_vector.content;
            int * new_arr;
            int len = roll_vector.length;

            int r = 0;
            for(int i = 0; i != amount_to_keep; i++){
                int m =  max(arr, len);
                new_vector.content[i] = m;
                new_arr = malloc(sizeof(int) *(len-1));
                pop(arr,len,m,new_arr);
                free(arr);
                arr = new_arr;
                len -= 1;
            }

            new_vector.dtype = roll_vector.dtype;
            $<values>$ = new_vector;
        }else{
            // Warning: More asked to keep than actually produced
            // or the same amount
            // e.g. 2d20k4 / 2d20kh2
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_LOWEST NUMBER
    {

        vec roll_vector, keep_vector;
        roll_vector = $<values>1;
        keep_vector = $<values>3;

        if (roll_vector.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        // assert $0 is len 1
        int available_amount =roll_vector.length;
        int amount_to_keep = keep_vector.content[0];

        if(available_amount > amount_to_keep){
            vec new_vector;
            new_vector.content = calloc(sizeof(int), amount_to_keep);
            new_vector.length = amount_to_keep;

            int * arr = roll_vector.content;
            int * new_arr;
            int len = roll_vector.length;

            int r = 0;
            for(int i = 0; i != amount_to_keep; i++){
                int m =  min(arr, len);
                new_vector.content[i] = m;
                new_arr = calloc(sizeof(int), len-1);
                pop(arr,len,m,new_arr);
                free(arr);
                arr = new_arr;
                len -= 1;
            }

            new_vector.dtype = roll_vector.dtype;
            $<values>$ = new_vector;
        }else{
            // Warning: More asked to keep than actually produced
            // or the same amount
            // e.g. 2d20k4 / 2d20kh2
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_HIGHEST
    {
        if ($<values>1.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        if($<values>1.length > 1){
            // print_vec($<values>1);
            int result = max($<values>1.content, $<values>1.length);
            vec vector;
            vector.content = malloc(sizeof(int));
            vector.content[0] = result;
            vector.length = 1;
            vector.dtype = $<values>1.dtype;
            $<values>$ = vector;
        }else{
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll KEEP_LOWEST
    {
        if ($<values>1.dtype == SYMBOLIC){
            printf("Symbolic Dice, Cannot determine value. Consider using filters instead");
            YYABORT;
            yyclearin;
        }
        if($<values>1.length > 1){
            // print_vec($<values>1);
            int result = min($<values>1.content, $<values>1.length);
            vec vector;
            vector.content = malloc(sizeof(int));
            vector.content[0] = result;
            vector.length = 1;
            vector.dtype = $<values>1.dtype;
            $<values>$ = vector;
        }else{
            $<values>$ = $<values>1;
        }
    }
    |
    die_roll
    {
        vec vector;
        vector = $<values>1;

        if (vector.dtype == SYMBOLIC){
            // Symbolic, Impossible to collapse
            $<values>$ = vector;
        }
        else{
            // Numeric.
            // Collapse if Nessicary
            if(vector.length > 1){
                int result = sum(vector.content, vector.length);
                vec new_vec;
                new_vec.dtype = vector.dtype;
                new_vec.content = malloc(sizeof(int));
                new_vec.content[0] = result;
                new_vec.length = 1;
                $<values>$ = new_vec;
            }else{
                $<values>$ = vector;
            }

        }
    }
die_roll:
    NUMBER SIDED_DIE NUMBER
    {
        // e.g. 2d20

        vec num_dice;
        num_dice = $<values>1;
        int instances = num_dice.content[0];
        int make_negative = false;
        if (instances == 0){
            vec new_vector;
            new_vector.content = malloc(sizeof(int)*instances);
            new_vector.content[0] = 0;
            new_vector.length = 1;
            $<values>$ = new_vector;
        }
        else if (instances < 0){
            make_negative = true;
            instances = instances * -1;
        }


        vec vector;
        vector = $<values>3;

        vec new_vector;
        new_vector.content = malloc(sizeof(int)*instances);
        new_vector.length = instances;

        int max = vector.content[0];
        int result = 0;
        if (max <= 0){
            printf("Cannot roll a dice with a negative amount of sides.");
            YYABORT;
            yyclearin;
        }else if (max > 0){
            for (int i = 0; i!= instances; i++){
                new_vector.content[i] += roll_numeric_die(1, max);
                if (make_negative) new_vector.content[i] *= -1;
            }
        }else{
            for (int i = 0; i!= instances; i++){
                new_vector.content[i] += 0;
            }
        }

        new_vector.dtype = NUMERIC;

        $<values>$ = new_vector;
    }
    |
    SIDED_DIE NUMBER
    {
        // e.g. d4, it is implied that it is a single dice
        vec vector;
        vector = $<values>2;
        int max = vector.content[0];
        int result = 0;
        if (max < 0){
            printf("Cannot roll a dice with a negative amount of sides.");
            YYABORT;
            yyclearin;
        }else if(max > 0){
            result = roll_numeric_die(1, max);
        } // else == 0




        vec new_vector;
        new_vector.content = malloc(sizeof(int));
        new_vector.content[0] = result;
        new_vector.length = 1;
        new_vector.dtype = NUMERIC;

        $<values>$ = new_vector;
    }
    |
    NUMBER FATE_DIE
    {
        // e.g. dF, it is implied that it is a single dice

        vec vector;
        vector = $<values>2;

        int instances =  $<values>1.content[0];

        vec new_vector;
        new_vector.symbols = malloc(sizeof(char**)*instances);
        new_vector.length = instances;
        new_vector.dtype = vector.dtype;
        int idx;

        for (int i = 0; i != instances;i++){
            idx = roll_symbolic_die(vector.length);
            new_vector.symbols[i] = vector.symbols[idx] ;
        }

        $<values>$ = new_vector;
    }
    |
    FATE_DIE
    {
        // e.g. dF, it is implied that it is a single dice

        vec vector;
        vector = $<values>1;
        int idx = roll_symbolic_die(vector.length);

        vec new_vector;
        new_vector.dtype = vector.dtype;
        new_vector.symbols = malloc(sizeof(char **));
        new_vector.symbols = &vector.symbols[idx];
        new_vector.length = 1;

        $<values>$ = new_vector;
    }
    |
    NUMBER
    ;

%%
/* Subroutines */
int main(){
    initialize();
    return(yyparse());
}

int yyerror(s)
const char *s;
{
    fprintf(stderr, "%s\n", s);
    return(1);
}

int yywrap(){
    return (1);
}
