module Syntax

layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;

keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new" | "override"
  | "if" | "then" | "else" | "for" | "in" | "true" | "false"
  | "and" | "or" | "neg"
  ;

lexical Identificador = ([a-zA-Z] [a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;

lexical NombreObjeto = @category="Type" Identificador;

lexical Entero = @category="Constant" EnteroTexto;
lexical EnteroTexto = [0-9]+ !>> [0-9];

lexical Decimal = @category="Constant" DecimalTexto;
lexical DecimalTexto = [0-9]+ "." [0-9]+ !>> [0-9];

lexical Booleano = @category="Constant" BooleanoTexto;
lexical BooleanoTexto = ("true" | "false") !>> [a-zA-Z0-9];

lexical Cadena = @category="Constant" CadenaTexto;
lexical CadenaTexto = "\"" ElementoCadena* "\"";
lexical ElementoCadena
  = CaracterTexto
  | "$" "{" Expresion "}"
  | "$" Identificador
  ;
lexical CaracterTexto = ![\"$];

start syntax S = programa: Instruccion* instrucciones;

syntax Instruccion
  = ObjetoCreador
  | VariableDeclaracion
  | VariableAsignacion
  | MetodoDeclaracion
  | Ciclo
  | instruccionExpresion: Expresion!igual e
  ;

syntax ObjetoCreador
  = objetoCreador: "object" NombreObjeto nombre ParametrosDefinicion? genericos Constructor? constructor Extiende? extiende
  ;

syntax Objeto = objeto: NombreObjeto nombre ParametrosUso? parametros;
syntax Extiende = "extends" Objeto ob;

syntax ParametrosDefinicion = "[" {ParametroDefinicion ","}+ parametros "]";

syntax ParametroDefinicion
  = covariante: "+" NombreObjeto nombre
  | contravariante: "-" NombreObjeto nombre
  | invariante: NombreObjeto nombre
  ;

syntax ParametrosUso = "[" {Objeto ","}+ objetos "]";

syntax Constructor = "(" {ParametroConstructor ","}+ parametros ")";

syntax ParametroConstructor
  = parametroVal: "val" Identificador nombre AnotacionTipo tipo
  | parametroVar: "var" Identificador nombre AnotacionTipo tipo
  ;

syntax AnotacionTipo = ":" Objeto ob;

syntax VariableDeclaracion
  = valDeclaracion: "val" Identificador nombre AnotacionTipo? tipo Inicializacion? valor
  | varDeclaracion: "var" Identificador nombre AnotacionTipo? tipo Inicializacion? valor
  ;

syntax Inicializacion = "=" Expresion valor;

syntax VariableAsignacion = variableAsignacion: RutaOVariable destino "=" Expresion valor;

syntax MetodoDeclaracion
  = MetodoPrincipal
  | MetodoExterno
  | MetodoOverride
  ;

syntax MetodoPrincipal = metodoPrincipal: "method" "main" Bloque b;

syntax MetodoExterno
  = metodoExterno: NombreObjeto nombre "." {Identificador "."}+ ruta "=" "method" "(" {ParametroMetodo ","}* parametros ")" AnotacionTipo? tipo CuerpoMetodo? cuerpo
  ;

syntax CuerpoMetodo
  = "=" Bloque b
  | Bloque b
  ;

syntax MetodoOverride
  = metodoOverride: "override" Identificador nombre "(" {ParametroMetodo ","}* parametros ")" AnotacionTipo? tipo "=" Bloque b
  ;

syntax ParametroMetodo = parametroMetodo: Identificador nombre AnotacionTipo tipo;

syntax Bloque = bloque: "{" Instruccion* instrucciones "}";

syntax Ciclo
  = ciclo: "for" "(" Patron patron OperadorIteracion operador Expresion coleccion ")" Cuerpo cuerpo
  ;

syntax Patron
  = patronVariable: Identificador nombre
  | patronTupla: "(" {Identificador ","}+ nombres ")"
  ;

syntax OperadorIteracion
  = desde: "\<-"
  | en: "in"
  ;

syntax Cuerpo
  = cuerpoBloque: Bloque b
  | cuerpoExpresion: Expresion e
  ;

syntax RutaOVariable
  = variable: Identificador id
  | acceso: RutaOVariable base "." Identificador campo
  | llamada: RutaOVariable base "(" {Expresion ","}* argumentos ")"
  ;

syntax Instanciacion
  = instanciacionConArgumentos: "new" Objeto ob "(" {Expresion ","}* argumentos ")" Bloque? cuerpo
  | instanciacionSimple: "new" Objeto ob !>> "(" Bloque? cuerpo
  ;

syntax Expresion
  = entero: Entero n
  | decimal: Decimal d
  | booleano: Booleano b
  | cadena: Cadena c
  | ruta: RutaOVariable r !>> "("
  | instanciacion: Instanciacion i
  | bracket "(" Expresion e ")"
  > negacion: "neg" Expresion e
  > left ( multiplicacion: Expresion izq "*" Expresion der
         | division: Expresion izq "/" Expresion der
         | modulo: Expresion izq "%" Expresion der
         | potencia: Expresion izq "**" Expresion der
         )
  > left ( suma: Expresion izq "+" Expresion der
         | resta: Expresion izq "-" Expresion der
         )
  > non-assoc ( menor: Expresion izq "\<" Expresion der
              | mayor: Expresion izq "\>" Expresion der
              | menorIgual: Expresion izq "\<=" Expresion der
              | mayorIgual: Expresion izq "\>=" Expresion der
              | distinto: Expresion izq "\<\>" Expresion der
              | igual: Expresion izq "=" Expresion der
              )
  > left ( conjuncion: Expresion izq "and" Expresion der
         | disyuncion: Expresion izq "or" Expresion der
         )
  > condicional: "if" Expresion condicion "then" Cuerpo entonces "else" Cuerpo sino
  ;
  