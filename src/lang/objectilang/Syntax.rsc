module lang::objectilang::Syntax

/*
 * Sintaxis concreta de Objectilang (Proyecto 2, Fase 4).
 *
 * Decisiones de diseño que cambian respecto al documento de gramática:
 *  - El menos unario "-" se elimina. Sin separadores entre sentencias,
 *    "a - b" también se podría leer como "a" seguido de "-b". La negación
 *    unaria se escribe con "neg".
 *  - Una referencia o un "new" seguido inmediatamente de "(" se lee como
 *    llamada o argumentos del constructor, no como una sentencia nueva.
 *  - "=" es asignación a nivel de sentencia y también igualdad en
 *    expresiones, como en la lista de símbolos del enunciado. Un "x = y"
 *    suelto puede salir ambiguo. Los ejemplos del enunciado no lo tienen.
 */

// ---------- Layout y comentarios ----------

layout Layout = WhitespaceOrComment* !>> [\ \t\n\r] !>> "//";

lexical WhitespaceOrComment
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;

// ---------- Palabras reservadas y léxico ----------

keyword Reserved
  = "object" | "extends" | "method" | "val" | "var" | "new" | "override"
  | "if" | "then" | "else" | "for" | "in" | "true" | "false"
  | "and" | "or" | "neg"
  ;

lexical Id = ([a-zA-Z] [a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reserved;
lexical IntLit = [0-9]+ !>> [0-9];
lexical RealLit = [0-9]+ "." [0-9]+ !>> [0-9];

lexical StringLit = "\"" StringPart* "\"";
lexical StringPart
  = StringChars
  | "$" Id
  | "${" Expr "}"
  ;
lexical StringChars = ![\"$]+ !>> ![\"$];

// ---------- Programa y sentencias ----------

start syntax Program = program: Stmt* stmts;

syntax Stmt
  = objectDef: "object" Id name TypeParams? tparams Constructor? ctor Extends? parent
  | valDecl: "val" Id name TypeAnnot? tp Init? init
  | varDecl: "var" Id name TypeAnnot? tp Init? init
  | assign: Ref target "=" Expr rhs
  | mainMethod: "method" "main" Block body
  | methodDef: Id owner "." {Id "."}+ names "=" "method" "(" {Param ","}* params ")" TypeAnnot? ret MethodBody? body
  | overrideDef: "override" Id name "(" {Param ","}* params ")" TypeAnnot? ret "=" Block body
  | forLoop: "for" "(" Pat pat IterOp op Expr src ")" Body body
  | exprStmt: Expr!eqOp e
  ;

// ---------- Objetos, tipos y genéricos ----------

syntax TypeParams = typeParams: "[" {TypeParam ","}+ params "]";

syntax TypeParam
  = covariant: "+" Id name
  | contravariant: "-" Id name
  | invariant: Id name
  ;

syntax Constructor = ctor: "(" {Field ","}+ fields ")";

syntax Field
  = valField: "val" Id name ":" TypeRef tp
  | varField: "var" Id name ":" TypeRef tp
  ;

syntax Extends = extendsClause: "extends" TypeRef parent;

syntax TypeRef = typeRef: Id name TypeArgs? args;
syntax TypeArgs = typeArgs: "[" {TypeRef ","}+ args "]";
syntax TypeAnnot = typeAnnot: ":" TypeRef tp;
syntax Init = init: "=" Expr rhs;

// ---------- Métodos ----------

syntax Param = param: Id name ":" TypeRef tp;
syntax MethodBody = methodBody: "="? Block block;
syntax Block = block: "{" Stmt* stmts "}";

// ---------- Control de flujo ----------

syntax Pat
  = varPat: Id name
  | tuplePat: "(" {Id ","}+ names ")"
  ;

syntax IterOp
  = fromOp: "\<-"
  | inOp: "in"
  ;

syntax Body
  = blockBody: Block b
  | exprBody: Expr e
  ;

// ---------- Referencias, llamadas y acceso ----------

syntax Ref
  = name: Id id
  | access: Ref target "." Id field
  | call: Ref target "(" {Expr ","}* args ")"
  ;

syntax NewArgs = newArgs: "(" {Expr ","}* args ")";

// ---------- Expresiones (de mayor a menor precedencia) ----------

syntax Expr
  = intLit: IntLit n
  | realLit: RealLit r
  | boolTrue: "true"
  | boolFalse: "false"
  | strLit: StringLit s
  | ref: Ref !>> "("
  | newObj: "new" TypeRef tp NewArgs args Block? body
  | newPlain: "new" TypeRef !>> "(" Block? body
  | bracket "(" Expr e ")"
  > right pow: Expr l "**" Expr r
  > negate: "neg" Expr e
  > left ( mul: Expr l "*" Expr r
         | div: Expr l "/" Expr r
         | modulo: Expr l "%" Expr r
         )
  > left ( add: Expr l "+" Expr r
         | sub: Expr l "-" Expr r
         )
  > non-assoc ( lt: Expr l "\<" Expr r
              | gt: Expr l "\>" Expr r
              | le: Expr l "\<=" Expr r
              | ge: Expr l "\>=" Expr r
              | ne: Expr l "\<\>" Expr r
              | eqOp: Expr l "=" Expr r
              )
  > left andOp: Expr l "and" Expr r
  > left orOp: Expr l "or" Expr r
  > ifExpr: "if" Expr cond "then" Body thenB "else" Body elseB
  ;
