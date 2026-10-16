module lang::objectilang::Syntax

/*
 * Sintaxis concreta de Objectilang (Proyecto 2).
 *
 * Sigue la gramática del Proyecto 1 con sus nombres en español. Rascal exige
 * que los no terminales empiecen con mayúscula, por eso objeto_creador se
 * escribe ObjetoCreador. Los ajustes respecto a esa gramática están
 * explicados en el documento de cambios.
 */

// ---------- Espacios y comentarios ----------

layout Layout = EspacioOComentario* !>> [\ \t\n\r] !>> "//";

lexical EspacioOComentario
  = [\ \t\n\r]
  | @category="Comment" "//" ![\n]* $
  ;

// ---------- Palabras reservadas, identificadores y literales ----------

keyword Reservada
  = "object" | "extends" | "method" | "val" | "var" | "new" | "override"
  | "if" | "then" | "else" | "for" | "in" | "true" | "false"
  | "and" | "or" | "neg"
  ;

lexical Identificador = ([a-zA-Z] [a-zA-Z0-9]* !>> [a-zA-Z0-9]) \ Reservada;

// Igual que Identificador. Existe solo para resaltar los nombres de objetos como tipos.
lexical NombreObjeto = @category="Type" Identificador;

// La anotación va sobre un solo no terminal. Si va directo sobre una secuencia
// como [0-9]+ "." [0-9]+, Rascal la lee como parte de una expresión y da ambigüedad.
lexical Numero = @category="Constant" NumeroTexto;
lexical NumeroTexto
  = [0-9]+ !>> [0-9]
  | [0-9]+ "." [0-9]+ !>> [0-9]
  ;

syntax Booleano
  = verdadero: "true"
  | falso: "false"
  ;

lexical Cadena = @category="Constant" CadenaTexto;
lexical CadenaTexto = "\"" ElementoCadena* "\"";
lexical ElementoCadena
  = CaracterTexto
  | "$" "{" Expresion "}"
  | "$" Identificador
  ;
lexical CaracterTexto = ![\"$];

// ---------- Programa e instrucciones ----------

start syntax S = s: Instruccion* instrucciones;

syntax Instruccion
  = ObjetoCreador
  | VariableDeclaracion
  | VariableAsignacion
  | MetodoDeclaracion
  | Ciclo
  | instruccionExpresion: Expresion!igual e
  ;

// ---------- Objetos y tipos ----------

syntax ObjetoCreador
  = objetoCreador: "object" NombreObjeto nombre ParametrosDefinicion? genericos Constructor? constructor Extiende? extiende
  ;

syntax Objeto = objeto: NombreObjeto nombre ParametrosUso? parametros;
syntax Extiende = extiende: "extends" Objeto ob;

syntax ParametrosDefinicion = parametrosDefinicion: "[" {ParametroDefinicion ","}+ parametros "]";

syntax ParametroDefinicion
  = covariante: "+" NombreObjeto nombre
  | contravariante: "-" NombreObjeto nombre
  | invariante: NombreObjeto nombre
  ;

syntax ParametrosUso = parametrosUso: "[" {Objeto ","}+ objetos "]";

syntax Constructor = constructor: "(" {ParametroConstructor ","}+ parametros ")";

syntax ParametroConstructor
  = parametroVal: "val" Identificador nombre AnotacionTipo tipo
  | parametroVar: "var" Identificador nombre AnotacionTipo tipo
  ;

syntax AnotacionTipo = anotacionTipo: ":" Objeto ob;

// ---------- Variables ----------

syntax VariableDeclaracion
  = valDeclaracion: "val" Identificador nombre AnotacionTipo? tipo Inicializacion? valor
  | varDeclaracion: "var" Identificador nombre AnotacionTipo? tipo Inicializacion? valor
  ;

syntax Inicializacion = inicializacion: "=" Expresion valor;

syntax VariableAsignacion = variableAsignacion: RutaOVariable destino "=" Expresion valor;

// ---------- Métodos ----------

syntax MetodoDeclaracion
  = MetodoPrincipal
  | MetodoExterno
  | MetodoOverride
  ;

syntax MetodoPrincipal = metodoPrincipal: "method" "main" Bloque b;

syntax MetodoExterno
  = metodoExterno: NombreObjeto nombre "." {Identificador "."}+ ruta "=" "method" "(" {ParametroMetodo ","}* parametros ")" AnotacionTipo? tipo CuerpoMetodo? cuerpo
  ;

syntax CuerpoMetodo = cuerpoMetodo: "="? Bloque b;

syntax MetodoOverride
  = metodoOverride: "override" Identificador nombre "(" {ParametroMetodo ","}* parametros ")" AnotacionTipo? tipo "=" Bloque b
  ;

syntax ParametroMetodo = parametroMetodo: Identificador nombre AnotacionTipo tipo;

// ---------- Bloques, ciclos y cuerpos ----------

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

// ---------- Rutas, llamadas e instanciación ----------

syntax RutaOVariable
  = variable: Identificador id
  | acceso: RutaOVariable ruta "." Identificador campo
  | llamada: RutaOVariable ruta "(" {Expresion ","}* argumentos ")"
  ;

// Un "(" pegado al objeto se lee como argumentos del constructor, no como una instrucción nueva.
syntax Instanciacion
  = instanciacionConArgumentos: "new" Objeto ob "(" {Expresion ","}* argumentos ")" Bloque? cuerpo
  | instanciacionSimple: "new" Objeto ob !>> "(" Bloque? cuerpo
  ;

// ---------- Expresiones (de mayor a menor precedencia) ----------

syntax Expresion
  = numero: Numero n
  | booleano: Booleano b
  | cadena: Cadena c
  | ruta: RutaOVariable !>> "("
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
