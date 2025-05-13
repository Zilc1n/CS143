

   # Cool 编译器支持代码参考

>   [!Note]
>
>   本文档是 Cool 编译器支持代码的参考指南，需结合源代码阅读。代码包含详细注释（除自动生成的 AST 包外），设计上优先简单性和正确性，而非性能优化。建议直接使用提供的实现，专注于功能开发，避免复杂优化。

   Cool 编译器支持代码用 C++ 编写，使用语言的简单子集（类、单一继承、虚函数、模板）。重载仅限于 `<<` 运算符，避免复杂性。内存管理被忽略以简化开发，开发者无需关注。

   **支持模块**：

   - 链表数据结构
   - 字符串表
   - 符号表
   - 词法分析与解析工具
   - 抽象语法树（AST）管理
   - AST 打印工具
   - 多文件与命令行处理
   - 运行时系统

---

   ## 链表

   `list.h` 提供简单链表实现，类似 Lisp 风格，支持以下接口：

   - **`List`**：在头部添加元素。
   - **`hd`**：返回首元素。
   - **`tl`**：返回除首元素外的链表。
   - **`length`**：返回链表长度。
   - **`map`**：对每个元素应用指定函数。
   - **`print`**：打印链表内容。

   **用法**：见字符串表和符号表实现。

---

   ## 字符串表

   字符串表（`stringtab.h`）管理标识符、数值常量、字符串常量，确保单一副本存储以优化空间和操作效率。实现基于链表（`stringtab_functions.h`），非哈希表，简化开发。

   **特性**：

   - **元素类型**：`Entry`，包含字符串、长度、唯一整数索引。
   - **三张表**：
     - `stringtable`：字符串常量。
     - `inttable`：整数常量。
     - `idtable`：标识符。
   - **类型**：各表使用 `StrEntry`、`IntEntry`、`IdEntry`，均继承自 `Entry`。`Entry` 指针称为 `Symbol`。

   **比较**：同一表内字符串比较通过指针相等性（`x == y`）。跨表比较无意义，即使内容相同，指针不同。

   **接口**（`stringtab.h`, `stringtab.cc`）：

   - **`Entry* add_string(char *s, int m)`**  
     - 插入最多 `m` 个字符的字符串 `s`，返回 `StrEntry` 或 `IdEntry` 指针。
   - **`Entry* add_string(char *s)`**  
     - 插入字符串 `s`，返回 `StrEntry` 或 `IdEntry` 指针。
   - **`IntEntry* add_int(int i)`**  
     - 将整数 `i` 转为字符串插入 `inttable`，返回 `IntEntry` 指针。
   - **`char* get_string()`**  
     - 从 `Entry` 派生类型提取字符串内容。

   **注意**：接口使用不当可能导致崩溃，需参考 `stringtab.cc` 文档。

---

   ## 符号表

   符号表（`symtab.h`）管理名称作用域，键为符号（`Symbol`），值为关联数据（如类型）。实现为作用域列表，每个作用域是（标识符，数据）对的链表。

   **特性**：

   - **作用域规则**：内部定义覆盖外部，`lookup` 返回最内层定义。
   - **用法示例**：见 `symtab_example.cc`。

   **接口**：

   - **`void addid(Symbol s, Data *d)`**  
     - 在当前作用域添加符号 `s` 和数据 `d`。
   - **`void enter_scope()`**  
     - 进入新作用域。
   - **`void exit_scope()`**  
     - 退出当前作用域。
   - **`Data* probe(Symbol s)`**  
     - 检查 `s` 是否在当前作用域，返回数据指针或 `nullptr`。
   - **`Data* lookup(Symbol s)`**  
     - 按作用域规则查找 `s`，返回数据指针或 `nullptr`。
   - **`void dump()`**  
     - 打印符号表，调试用。

---

   ## 实用工具

   `utilities.h` 和 `utilities.cc` 提供词法分析和解析的辅助函数，接口如下：

   - **`void fatal_error(char *msg)`**  
     - 打印错误消息 `msg`，终止程序。
   - **`void print_escaped_string(ostream& str, const char *s)`**  
     - 将字符串 `s` 打印到流 `str`，转义特殊字符（如 `\n` 打印为 `\\n`），不可打印字符用八进制表示。
   - **`char* cool_token_to_string(int tok)`**  
     - 将 token 整数值转为字符串（如 `CLASS`、`IF`），返回字符串指针，调试用。
   - **`void print_cool_token(int tok)`**  
     - 打印 token 名称及其语义值（如字符串、整数、标识符）到 `cerr`，调试用。
   - **`void dump_cool_token(ostream& out, int lineno, int token, YYSTYPE yylval)`**  
     - 格式化输出 token（行号、名称、语义值）到流 `out`，转义字符串值，用于验证词法分析。
   - **`char* strdup(const char *s)`**  
     - 复制字符串 `s`，返回新指针，`NULL` 输入返回 `NULL`，确保跨平台兼容。
   - **`char* pad(int n)`**  
     - 返回 `n` 个空格的字符串，`n  80` 返回最大填充，`n <= 0` 返回空字符串，用于格式化输出（如 AST 缩进）。

---

   ## 抽象语法树（AST）

   AST 表示解析后的 Cool 程序，从 `cool-tree.aps` 自动生成，代码简单但无注释。本节提供接口和使用指南。

   ### Phyla 与 Constructors

   AST 节点（constructors）按功能分组为 phyla（类型），如：

   - **普通 phyla**：`Program`、`Class_`、`Feature`、`Expression`。
   - **列表 phyla**：`Classes`（`List[Class_]`）、`Features`（`List[Feature]`）。

   **示例**：

   ```c++
constructor class_(name: Symbol; parent: Symbol; features: Features; filename: Symbol) Class_;
   ```

   - 接受类名、父类、特征列表、文件名，返回 `Class_` 节点。

   ### AST 列表

   列表 phyla 提供操作接口（以 `Classes` 为例）：

   - **`Classes nil_Classes()`**  
     - 返回空 `Classes` 列表。
   - **`Classes single_Classes(Class_ c)`**  
     - 创建单元素列表，包含 `Class_` 节点 `c`。
   - **`Classes append_Classes(Classes c1, Classes c2)`**  
     - 连接两个 `Classes` 列表。
   - **`Class_ nth(int index)`**  
     - 返回第 `index` 个元素。
   - **`int len()`**  
     - 返回列表长度。
   - **迭代器**：
     - **`int first()`**：返回首元素索引。
     - **`bool more(int i)`**：检查索引 `i` 是否为末尾。
     - **`int next(int i)`**：返回下一个索引。

   **迭代示例**：

   ```cpp
for (int i = l-first(); l-more(i); i = l-next(i)) {
    // 处理 l-nth(i)
}
   ```

   ### AST 类层次

   所有 AST 类继承自 `tree_node`，列表为 `tree_node` 列表。`tree_node` 接口：

   - **`int get_line_number()`**  
     - 返回节点对应的源文件行号。
   - **`void dump(ostream& str, int indent)`**  
     - 格式化打印 AST 节点，带缩进。

   Constructors 定义同名函数构建节点，并自动生成 `dump`。

   ### 类成员

   Constructor 参数成为数据成员，仅类及其派生类成员函数可访问。例如：

   ```cpp
class__class c = class_(idtable.add_string("Foo"), idtable.add_string("Bar"), nil_Features(), stringtable.add_string("filename"));
Symbol p = c-get_parent(); // 返回 "Bar"
   ```

   **添加新成员**：
   在 `cool-tree.h` 中为 phylum 或 constructor 添加函数，如：

   ```cpp
Symbol class__class::get_parent() { return parent; }
   ```

   ### Constructor 接口

   以下为主要 constructor，参数顺序遵循 Cool 语法：

   - **`program(Classes classes)`**  
     - 构建程序节点，接受类列表。
   - **`class_(Symbol name, Symbol parent, Features features, Symbol filename)`**  
     - 构建类节点。
   - **`method(Symbol name, Formals formals, Symbol return_type, Expression expr)`**  
     - 构建方法节点。
   - **`attr(Symbol name, Symbol type, Expression init)`**  
     - 构建属性节点，`init` 可选。
   - **`formal(Symbol name, Symbol type)`**  
     - 构建方法形式参数。
   - **`branch(Symbol name, Symbol type, Expression expr)`**  
     - 构建 case 分支。
   - **`assign(Symbol name, Expression expr)`**  
     - 构建赋值表达式。
   - **`static_dispatch(Expression expr, Symbol type, Symbol name, Expressions args)`**  
     - 构建静态分派。
   - **`dispatch(Expression expr, Symbol name, Expressions args)`**  
     - 构建动态分派，`expr` 通常为 `self`。
   - **`cond(Expression pred, Expression then_exp, Expression else_exp)`**  
     - 构建 if-then-else。
   - **`loop(Expression pred, Expression body)`**  
     - 构建 loop-pool。
   - **`typcase(Expression expr, Cases cases)`**  
     - 构建 case 表达式。
   - **`block(Expressions exprs)`**  
     - 构建块表达式。
   - **`let(Symbol name, Symbol type, Expression init, Expression body)`**  
     - 构建 let 表达式，需手动转换嵌套 let。
   - **`plus`, `sub`, `mul`, `divide`, `neg`, `lt`, `eq`, `leq`, `comp`**  
     - 构建算术、比较、逻辑表达式。
   - **`int_const(Symbol val)`**  
     - 构建整数常量。
   - **`bool_const(bool val)`**  
     - 构建布尔常量。
   - **`string_const(Symbol val)`**  
     - 构建字符串常量。
   - **`new_(Symbol type)`**  
     - 构建 new 表达式。
   - **`isvoid(Expression expr)`**  
     - 构建 isvoid 表达式。
   - **`no_expr()`**  
     - 构建空表达式，适用于可选表达式缺失（除 `dispatch` 的 `self`）。
   - **`object(Symbol name)`**  
     - 构建对象标识符表达式。

   ### AST 使用注意

   - **接口遵守**：AST 是抽象数据类型，勿通过类型转换或指针算术绕过接口。
   - **避免 NULL**：constructor 参数不能为 `NULL`，用 `nil_phylum` 表示空列表。
   - **列表比较**：`x == nil_Expression()` 恒为假，用 `len()` 检查空列表。
   - **节点比较**：`x == no_expr()` 无意义，需定义虚方法检查 constructor 类型。
   - **错误处理**：AST 函数检测错误时调用 `fatal_error`，用调试器定位问题。

---

   ## 运行时系统

   运行时系统由汇编函数组成，位于 `trap.handler`，自动加载到 spim/xspim。包含：

      1. **启动代码**：调用 `Main.main`。
      2. **预定义类方法**：支持 `Object`、`IO`、`String`。
      3. **运行时支持**：对象相等性测试、错误处理。
      4. **垃圾收集器**：分代（默认）和停止复制收集器。

   ### 对象布局

   对象结构：

   - **头部**：类标签（32 位整数）、对象大小、分派指针。
   - **垃圾收集标签**：对象前一字，值为 -1。
   - **属性**：
     - `Int`：32 位整数。
     - `Bool`：1（true）或 0（false）。
     - `String`：大小（`Int` 指针）+ ASCII 字符（0 终止，字边界填充）。
     - `void`：`NULL` 指针（32 位 0）。

   ### 原型对象

   每个类需定义原型对象，供 `Object.copy` 创建实例。代码生成器需初始化垃圾收集标签、类标签、对象大小和分派信息。

   ### 寄存器与栈

   - **参数**：`self` 在 `$a0`，其他参数压栈（先入栈者为第一个参数）。
   - **寄存器**：临时寄存器可能被修改，堆指针和 limit 指针由运行时管理。

   ### 运行时函数接口

   - **`Object.copy`**  
     - 复制 `$a0` 中的对象，返回新对象（`$a0`）。
   - **`Object.abort`**  
     - 打印 `$a0` 中对象类名，终止程序。
   - **`Object.type_name`**  
     - 返回 `$a0` 中对象类名（字符串对象，`$a0`）。
   - **`IO.out_string`**  
     - 打印栈顶字符串值，不改 `$a0`。
   - **`IO.out_int`**  
     - 打印栈顶整数值，不改 `$a0`。
   - **`IO.in_string`**  
     - 读取终端字符串，返回字符串对象（`$a0`）。
   - **`IO.in_int`**  
     - 读取终端整数，返回整数对象（`$a0`）。
   - **`String.length`**  
     - 返回 `$a0` 中字符串长度（整数对象，`$a0`）。
   - **`String.concat`**  
     - 连接栈顶字符串与 `$a0` 中字符串，返回新字符串（`$a0`）。
   - **`String.substr`**  
     - 返回 `$a0` 中字符串的子字符串，从栈中次顶索引 `i` 开始，长度为栈顶 `l`，结果在 `$a0`。
   - **`equality_test`**  
     - 比较 `$t1` 和 `$t2` 中基本类型对象（`Int`、`String`、`Bool`），相等返回 `$a0`，否则返回 `$a1`。
   - **`dispatch_abort`**  
     - 处理 void 对象分派，打印行号（`$t1`）和文件名（`$a0`），终止。
   - **`case_abort`**  
     - 处理 case 无匹配，打印 `$a0` 中对象类名，暂停执行。
   - **`case_abort2`**  
     - 处理 void 对象的 case，打印行号（`$t1`）和文件名（`$a0`），终止。

   ### 执行流程

      1. 创建并初始化 `Main` 对象，调用 `Main.init`。
      2. 调用 `Main.main`，`$a0` 传递 `Main` 对象指针，`$ra` 含返回地址。
      3. 返回后显示“COOL program successfully executed”。

   ### 垃圾收集器

   支持分代（默认）和停止复制收集器。代码生成器需：

   - **配置**：设置 `MemMgr_INITIALIZER` 和 `MemMgr_COLLECTOR` 指向收集器例程。
   - **栈与对象**：确保栈上偶数堆地址和对象中的有效堆地址指向对象。
   - **属性赋值**：调用 `GenGC_Assign`，参数为更新地址（`$a1`）。

   **示例**：

   ```c++
sw $x 12($self)
addiu $a1 $self 12
jal _GenGC_Assign
   ```

