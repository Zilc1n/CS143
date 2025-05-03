
%option noyywrap
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

// 嵌套注释的个数
int comment_num = 0;

// 设置为默认状态并报错
#define ERROR_AND_INIT \
  BEGIN(INITIAL); \
  return ERROR;

// 检测字符串的长度
#define CHECK_STR_LEN \
  if (string_buf_ptr - string_buf >= MAX_STR_CONST) \
  { \
    char ch; \
    cool_yylval.error_msg = "String constant too long"; \
    while((ch = yyinput()) != '\"' && ch != EOF) \
      continue; \
    ERROR_AND_INIT \
  }
%}

/* start condition */
%x SINGLE_COMMENT
%x MORE_COMMENT
%x STRING

/*
 * Define names for regular expressions here.
 */

CLASS     (?i:class)
ELSE      (?i:else)
FI        (?i:fi)
IF        (?i:if)
IN        (?i:in)
INHERITS  (?i:inherits)
LET       (?i:let)
LOOP      (?i:loop)
POOL      (?i:pool)
THEN      (?i:then)
WHILE     (?i:while)
CASE      (?i:case)
ESAC      (?i:esac)
OF        (?i:of)
NEW       (?i:new)
ISVOID    (?i:isvoid)
NOT       (?i:not)
TRUE      (t(?i:rue))
FALSE     (f(?i:alse))

DIGIT     [0-9]
INT       {DIGIT}+
LETTER    [a-zA-Z]
ID        ({LETTER}|{DIGIT}|_)
TYPEID    [A-Z]{ID}*
OBJID     [a-z]{ID}*

WHITESPACE  [\ \t\b\f\r\v]*
SINGLE_OPERATOR      [\<\=\+/\-\*\.~\,;\:\(\)@\{\}]

%%

 /*
  *  Nested comments
  */

"--"                                  { BEGIN(SINGLE_COMMENT); }
<SINGLE_COMMENT>.                     {}
<SINGLE_COMMENT><<EOF>>               { BEGIN(INITIAL); }
<SINGLE_COMMENT>\n                    { BEGIN(INITIAL); ++curr_lineno; }

"(*" {
  comment_num++; /* 递增嵌套层级 */
  BEGIN(MORE_COMMENT); /* 进入注释状态 */
}

<MORE_COMMENT>"(*" {
  comment_num++; /* 处理嵌套注释 */
}              
<MORE_COMMENT>"*)"                    {
  if (!--comment_num) {
    BEGIN(INITIAL);
  }
}
<MORE_COMMENT><<EOF>>                 {
  yylval.error_msg = "EOF in comment";
  ERROR_AND_INIT;
}
<MORE_COMMENT>\n                      { ++curr_lineno; }
<MORE_COMMENT>.                       {}

<INITIAL>"*)"                         {
  yylval.error_msg = "Unmatched *)";
  return ERROR;
}

{WHITESPACE}                          {}

 /*
  *  The multiple-character operators.
  */

"=>"	                { return DARROW; }
"<-"                  { return ASSIGN; }
"<="                  { return LE; }
{SINGLE_OPERATOR}     { return *yytext; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}     { return CLASS; }
{FI}        { return FI;    }
{IF}        { return IF;    }
{ELSE}      { return ELSE;  }
{IN}        { return IN;    }
{INHERITS}  { return INHERITS;}
{LET}       { return LET;   }
{LOOP}      { return LOOP;  }
{POOL}      { return POOL;  }
{THEN}      { return THEN;  }
{WHILE}     { return WHILE; }
{CASE}      { return CASE;  }
{ESAC}      { return ESAC;  }
{OF}        { return OF;    }
{NEW}       { return NEW;   }
{ISVOID}    { return ISVOID;}
{NOT}       { return NOT;   }

{TRUE}      {
  yylval.boolean = true;
  return BOOL_CONST;
}
{FALSE}     {
  yylval.boolean = false;
  return BOOL_CONST;
}

{TYPEID}    {
  yylval.symbol = idtable.add_string(yytext);
  return TYPEID;
}

{OBJID}     {
  yylval.symbol = idtable.add_string(yytext);
  return OBJECTID;
}

{INT}       {
  yylval.symbol = idtable.add_string(yytext);
  return INT_CONST;
}


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
"\""   { 
  string_buf_ptr = string_buf;
  BEGIN(STRING); 
};
<STRING>\\[^\0]   {
  char ch = yytext[1];
  if(ch == 'b')
    *string_buf_ptr++ = '\b';
  else if(ch == 't')
    *string_buf_ptr++ = '\t';
  else if(ch == 'n')
    *string_buf_ptr++ = '\n';
  else if(ch == 'f')
    *string_buf_ptr++ = '\f';
  else
    *string_buf_ptr++ = ch;
  CHECK_STR_LEN
}

<STRING>"\""    {
  BEGIN(INITIAL);
  *string_buf_ptr++ = '\0';
  cool_yylval.symbol = stringtable.add_string(string_buf);
  return STR_CONST; 
}
<STRING>"\\\n"   {
  *string_buf_ptr++ = '\n'; 
  curr_lineno++;
  CHECK_STR_LEN
}
<STRING><<EOF>>  {
  cool_yylval.error_msg = "EOF in string constant";
  ERROR_AND_INIT
}
<STRING>"\0"    {
  char ch;
  char isEscaped = false;
  while((ch = yyinput()) != '\n' && ch != EOF)
  {
    if (ch == '\"')
    {
      isEscaped = true;
      break;
    }
  }
  if (isEscaped)
    cool_yylval.error_msg = "String contains escaped null character.";
  else 
    cool_yylval.error_msg = "String contains null character.";
  
  ERROR_AND_INIT
}

<STRING>\n      {
  cool_yylval.error_msg = "EOF in string constant";
  curr_lineno++;
  ERROR_AND_INIT
}

<STRING>.       {
  *string_buf_ptr++ = *yytext;
  CHECK_STR_LEN
}

 /* 如果在字符串范围外发现反斜杠，则报错 */
\\ {
  cool_yylval.error_msg = strdup(yytext);
  return ERROR; 
}

\n { curr_lineno++; }

 /* 如果还有尚未处理的字符（可能是非cool语法的字符），则报错 */
. {
  cool_yylval.error_msg = strdup(yytext);
  return ERROR; 
}

%%
