/*
 * cool.y
 * 解析器定义，用于COOL语言。
 */
%{
#include <iostream>
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

extern char *curr_filename;

/* 位置信息 */
#define YYLTYPE int              /* 位置的类型 */
#define cool_yylloc curr_lineno  /* 使用词法分析器中的curr_lineno作为令牌的位置 */

extern int node_lineno;          /* 在构造树节点之前设置，用于指定树节点的行号 */

#define YYLLOC_DEFAULT(Current, Rhs, N)         \
    Current = Rhs[1];                           \
    node_lineno = Current;

#define SET_NODELOC(Current)  \
    node_lineno = Current;

/* 关于行号的重要说明
 * 
 * - 上述定义和宏确保语法中的每个终结符都具有词法分析器提供的行号。
 * - 要使行号正常工作，您唯一需要实现的任务是：
 *   在从语法中的非终结符构造任何结构之前使用SET_NODELOC()。
 * 
 * - 示例：假设您正在匹配以下非常限制性的（虚构）构造，
 *   该构造匹配两个整数常量之间的加号。
 *   （这样的规则不应是您解析器的一部分）：
 * 
 *   plus_consts : INT_CONST '+' INT_CONST
 * 
 * - 其中INT_CONST是整数常量的终结符。现在，为该规则提供正确的操作，
 *   以将正确的行号附加到plus_const，将如下所示：
 * 
 *   plus_consts : INT_CONST '+' INT_CONST 
 *   {
 *     // 设置当前非终结符的行号：
 *     // ***
 *     // 您可以通过@i访问第i个项目的行号，
 *     // 就像通过$i访问第i个表达式的值一样。
 *     //
 *     // 这里，我们选择最后一个INT_CONST (@3)的行号作为
 *     // 结果表达式(@$)的行号。您可以自由选择任何合理的行号
 *     // 作为非终结符的行号。如果您省略@$=...语句，
 *     // bison有默认规则来决定使用哪个行号。如果您有兴趣，
 *     // 请查阅手册以获取详细信息。
 *     @$ = @3;
 *     
 *     // 请注意，我们调用SET_NODELOC(@3)；
 *     // 这会将全局变量node_lineno设置为@3。
 *     // 由于“plus”构造函数调用使用此全局变量的值，
 *     // plus节点现在将具有正确的行号。
 *     SET_NODELOC(@3);
 *     
 *     // 构造结果节点：
 *     $$ = plus(int_const($1), int_const($3));
 *   }
 */

void yyerror(char *s);        /* 定义在下方；每次解析错误时调用 */
extern int yylex();           /* 词法分析器的入口点 */

//
// /* 不要更改此部分中的任何内容 */
//

Program ast_root;            /* 解析结果 */
Classes parse_results;       /* 用于语义分析 */
int omerrs = 0;              /* 词法分析和解析中的错误数量 */
%}

/* 所有解析动作结果类型的联合 */
%union {
    Boolean boolean;
   editorial::Symbol symbol;
    Program program;
    Class_ class_;
    Classes classes;
    Feature feature;
    Features features;
    Formal formal;
    Formals formals;
    Case case_;
    Cases cases;
    Expression expression;
    Expressions expressions;
    char *error_msg;
}

/* 
 * 声明终结符；一些终结符具有关联词素的类型。
 * ERROR令牌从不在解析器中使用；因此，当词法分析器返回它时，
 * 会导致解析错误。
 * 
 * 令牌声明后的整数是内部用于表示该令牌的数字常量。
 * 通常，Bison会自动生成这些数字，但我们给出明确的数字，
 * 以防止版本奇偶校验问题（bison 1.25及更早版本从258开始，
 * 更高版本从257开始）。
 */
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol> STR_CONST 275 INT_CONST 276 
%token <boolean> BOOL_CONST 277
%token <symbol> TYPEID 278 OBJECTID 279 
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/* 不要更改此行以上的任何内容，否则您的解析器将无法工作 */
/**/

 /* 下面完成非终结符列表，为每个非终结符的语义值指定类型。
  * （详见bison文档的第3.6节）。
  */

/* 为语法的非终结符声明类型 */
%type <program> program
%type <classes> class_list
%type <class_> class

/* 您需要更改以下行 */
%type <features> dummy_feature_list

/* 此处放置优先级声明 */
%right NOT ASSIGN
%nonassoc LE '=' '<' /* ' */
%left '+' '-'
%left '*' '/'
%right '~' ISVOID
%%
/* 
 * 将抽象语法树的根保存在全局变量中。
 */
program : class_list { @$ = @1; ast_root = program($1); }
;

class_list
: class /* 单个类 */
{ $$ = single_Classes($1);
  parse_results = $$; }
| class_list class /* 多个类 */
{ $$ = append_Classes($1, single_Classes($2)); 
  parse_results = $$; }
;

/* 如果未指定父类，则该类继承自Object类 */
class : CLASS TYPEID '{' dummy_feature_list '}' ';'
{ $$ = class_($2, idtable.add_string("Object"), $4,
    stringtable.add_string(curr_filename)); }
| CLASS TYPEID INHERITS TYPEID '{' dummy_feature_list '}' ';'
{ $$ = class_($2, $4, $6, stringtable.add_string(curr_filename)); }     // 类名，父节点，特征，类定义的文件名
;

/* 特征列表可以为空，但列表中不能有空特征 */
dummy_feature_list: /* 空 */
{ $$ = nil_Features(); }

/* 语法结束 */
%%

/* 当Bison检测到解析错误时，会自动调用此函数 */
void yyerror(char *s)
{
    extern int curr_lineno;

    cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
         << s << " at or near ";
    print_cool_token(yychar);
    cerr << endl;
    omerrs++;

    if (omerrs > 50) {
        fprintf(stdout, "More than 50 errors\n");
        exit(1);
    }
}