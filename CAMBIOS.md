# CAMBIOS — Proyecto 3

## Fase 1 — Entorno
- Extensión de programas `.obj` pasa a `.ol` (ejemplos renombrados con `git mv`; `Plugin.rsc`, `Check.rsc` e `Implode.rsc` actualizados).
- `META-INF/RASCAL.MF`: `Require-Libraries: |lib://typepal|` para instalar TypePal (jar 0.8.6 en el repositorio Maven local).
- Ejecución con TypePal desde terminal:
  `java -cp /usr/share/java/rascal/rascal-0.33.8.jar:$HOME/.m2/repository/org/rascalmpl/typepal/0.8.6/typepal-0.8.6.jar org.rascalmpl.shell.RascalShell`

## Fase 2 — Correcciones del P1/P2
- **Cadenas (`AsParteCadena`)**: nuevo módulo `Cadenas.rsc` con `Cadena`/`ParteCadena` como `syntax` y constructores `cadenaLiteral`, `parteTexto`, `parteVariable`, `parteExpresion` que coinciden 1 a 1 con el AST. Se eliminó el parseo manual (`partesCadena`, `estructurarCadenas`, `expresionDesdeTexto`) de `Implode.rsc`; ahora todo sale de `implode`.
  - El módulo no importa `Syntax`, por lo que no hereda su `layout`: los espacios del texto se conservan. `Parser.rsc` importa ambos módulos para que el parser generado incluya la gramática de cadenas; `Check.rsc` y `Plugin.rsc` parsean a través de `Parser.rsc`.
- **Interpolación**: `Interpolacion = "${" Expresion e "}"` es `syntax` (con layout), así `${ x }` deriva. El texto (`TextoCadena`) sigue siendo `lexical`.
- **AST**: `cadena(str)` y `cadenaCompuesta` pasan a `cadena(AstCadena)` con `cadenaLiteral(list[AstParteCadena])`.
- **`bracket`**: reemplazado por `parentesis` con constructor `parentesis(AstExpresion e)` en el AST.
- **`->`**: tipos función, `tipoFuncion(list[AstObjeto] parametros, AstObjeto resultado)` dentro de `Objeto` (`(Int, Int) -> Int`, `List[(Int) -> Int]`).
- **`=>`**: lambdas con precedencia mínima, `lambda(parametros, AstExpresion cuerpo)` y `lambdaBloque(parametros, AstBloque)`. Cuerpo de expresión y de bloque son producciones separadas para que la prioridad desambigüe `(x: Int) => x + 1`.
- **Condicional**: `if a then b else c + 1` era ambiguo (el `else Cuerpo` rompía el filtro de prioridades). Se separó en `condicional` (rama `else` expresión) y `condicionalBloque` (rama `else` bloque).
- Opcionales como `list[...]` en el AST se mantienen: es la forma en que `implode` representa `X?`.
- Ejemplos nuevos: `cadenas.ol`, `parentesis.ol`, `flecha.ol`, `lambda.ol`.
- Verificado: `checkExamples()` y `checkAst()` pasan sobre los 8 ejemplos, sin ambigüedades.
- `Plugin.rsc`/`Check.rsc`: se quitaron comentarios. `Plugin.rsc` solo carga en VS Code (necesita `rascal-lsp`).

## Fase 3 — Parser e implode
- Nuevo `Pruebas.rsc` (se corre con `import Pruebas; :test`): 16 pruebas.
  - Todos los `.ol` de `examples/` parsean y generan AST.
  - Todos los `.ol` de `examples/invalidos/` (10 casos: cadena sin cierre, paréntesis sin cerrar, interpolación vacía, flecha incompleta, lambda sin tipo, char vacío o largo, comparación encadenada, genéricos vacíos, anotación sin tipo) fallan con error de parseo.
  - Pruebas de forma del AST: interpolación con espacios, `$variable`, cadena vacía, espacios del texto, paréntesis, precedencia, `->`, `=>`, condicional sin ambigüedad, `Char`, tipos genéricos.

## Fase 4 — Anotaciones de tipo
- Decisión: `Int`, `Boolean`, `Char` y `String` son `NombreObjeto` (tipos como objetos), no palabras reservadas. TypePal los tratará como tipos base.
- Nuevo literal `Char`: `'a'` (`Caracter`/`CaracterSimple` en `Cadenas.rsc`, sin layout para conservar el espacio `' '`). AST: `caracter(AstCaracter)` con `caracterLiteral(str valor)`.
- Ya existían anotaciones en `val`/`var`, parámetros de método y de constructor, y tipo de retorno; los genéricos del usuario van en `object Caja[T]` y `Caja[Int]` (anidables: `Caja[Caja[Int]]`). Se probaron en `examples/tipos.ol`.
- Ejemplos nuevos: `tipos.ol`, `caracteres.ol`.

## Fase 5 — TypePal (`TypeChecker.rsc`)
- Nuevo módulo `TypeChecker.rsc`: `collect` sobre el árbol concreto, `data AType`, roles (`IdRole`) y configuración (`isSubType`, `getTypeNamesAndRole`). Puntos de entrada: `modeloDeTipos(Tree)`, `verificarTexto(str)`, `verificarArchivo(loc)`, `erroresDeTexto`/`erroresDeArchivo`.
- Tipos: `Int`, `Decimal`, `Boolean`, `Char`, `String`, `Unit`, instancias de objeto con argumentos (`Caja[Int]`), parámetros de tipo y tipos función (`(Int) -> Int`). `Int` es subtipo de `Decimal`.
- Declaraciones: `val`/`var` con tipo, con valor o ambos (tipo inferido del valor); `val` y parámetros no se pueden reasignar. Chequeo de asignación por subtipo.
- Objetos: campos del constructor, herencia (`extends`, con acceso a campos y métodos heredados), genéricos con inferencia en `new Caja(1)` y verificación de aridad. Los métodos externos (`Objeto.metodo = method(...)`) se definen en el alcance del objeto y ven sus campos y parámetros de tipo.
- Varianza: `+`/`-`/invariante se aplican en el subtipado (`Lista[Perro] <: Lista[Animal]` solo si `+A`; `Transformer[-In, +Out]` contravariante en la entrada). Además se rechaza un parámetro covariante en campo `var` o parámetro de método, y uno contravariante en campo o retorno.
- `override` dentro de `new X { ... }`: el método debe existir y la firma (con los argumentos de tipo sustituidos) debe ser compatible.
- Expresiones: aritmética, orden, igualdad, lógicos, `neg`, condicional (ramas unidas por supertipo común), lambdas, llamadas con chequeo de aridad y tipos, cadenas con interpolación (variables y expresiones deben existir).
- `for (x <- coleccion)`: las variables toman los argumentos de tipo de la colección (`for ((k, v) <- m)` sobre `M[K, V]`).
- Decisiones: `print`/`println` devuelven el tipo de su primer argumento (así `Cat.talk = method(): String { print("...") }` tipa); `getClass.getSimpleName` se trata como miembro predefinido (lo usa el ejemplo de `transformer.ol`); las rutas de método solo soportan un nivel (`Objeto.metodo`).
- Se corrigió `examples/transformer.ol`: `Transform.transform` era un error de escritura de `Transformer.transform` (con la nueva regla de existencia habría fallado).
- Nota: TypePal imprime `Skipping (type-incorrect) def` por consola cuando un programa inválido deja definiciones sin resolver; es salida de la librería.
- Mensajes de TypePal como `Undefined ...` se mantienen en inglés (vienen de la librería); los propios están en español.

## Fase 6 — Regla de existencia
- La regla se implementa con las referencias de TypePal: todo nombre usado en una definición de objeto debe resolverse. Cubre el objeto padre (`extends`), los tipos de los campos del constructor, los parámetros de tipo, los argumentos de tipo (`Caja[Fantasma]`), el objeto de un método externo, los métodos de `override`, los campos y métodos accedidos y los objetos instanciados con `new`. Los objetos pueden usarse antes de definirse.
- Ejemplo válido: `examples/tipado/validos/existencia.ol` (referencias hacia adelante, genéricos, herencia, método externo y `override`).
- Ejemplos inválidos en `examples/tipado/invalidos/` (12 archivos, uno por causa): padre, tipo de campo, parámetro de tipo, padre genérico, argumento de tipo, instancia, objeto de método externo, override, campo, método y variable inexistentes, y objeto duplicado.
- Nuevo `PruebasTipos.rsc` (`import PruebasTipos; :test`): 14 pruebas. Los válidos no producen errores, los inválidos sí, y cada error nombra el elemento que falta.
- Limitación de la gramática: no se puede encadenar sobre una instanciación (`new A.metodo()`); hay que guardarla en un `val`.

## Fase 7 — Intérprete y Main

- `src/Interprete.rsc`: intérprete sobre el AST. Estado en variables del módulo (ámbitos encadenados, memoria de instancias, definiciones de objetos, métodos externos y salida). Cubre aritmética Int/Decimal, cadenas con interpolación, Char, Boolean con cortocircuito, `if`, lambdas con cierre, objetos, campos `var` mutables, métodos externos, `override` en `new`, herencia de métodos, `getClass.getSimpleName`, `print`/`println` y `for` sobre instancias (recorre sus campos; la tupla destructura los campos del elemento).
- Los objetos y métodos externos se registran antes de ejecutar, así que pueden usarse antes de definirse. `method main` se ejecuta en su posición.
- Errores de ejecución (`errorEjecucion`): división por cero, variable no definida, aridad incorrecta, miembro inexistente.
- `src/Main.rsc`: `ejecutar(loc)` parsea, tipa con TypePal y solo si no hay errores ejecuta imprimiendo únicamente la salida del programa. `main(["ruta.ol"])` es el punto de entrada.
- Ejemplos en `examples/ejecucion/` y pruebas en `src/PruebasEjecucion.rsc` (9/9).
- Limitaciones: los `val`/`var` no se verifican en ejecución (lo hace TypePal); no hay colecciones nativas, `for` itera los campos de una instancia; `%` y `**` con decimales son aproximados.

## Fase 8 — Pruebas
- Se agregaron 19 `.ol` inválidos de tipos en `examples/tipado/invalidos/` (prefijo `tipo_`): asignación con tipo incorrecto, `Char` vs `String`, operador aritmético y lógico, `neg`, ramas de `if`, subtipo, invarianza, covarianza inválida, varianza en campo `var` y en parámetro de método, argumentos y aridad de constructor, argumentos y retorno de método, reasignar un `val`, asignar un tipo incorrecto a una `var`, tipo de lambda y llamar un valor que no es función. Cada uno se verifica por el texto del mensaje de error.
- `src/PruebasTipos.rsc`: 33 pruebas (14 de existencia + 19 de tipos).
- Nuevo `src/PruebasPipeline.rsc` (8 pruebas): los `.ol` válidos pasan por parseo, AST, TypePal y ejecución; los inválidos de sintaxis no parsean; los inválidos de tipos sí parsean pero TypePal reporta error y no se ejecutan.
- Totales: `Pruebas` 16, `PruebasTipos` 33, `PruebasEjecucion` 9, `PruebasPipeline` 8 = 66 pruebas, todas pasan.
- Ejecución de las pruebas (REPL con TypePal en el classpath): `import <Modulo>; :test`.

## Insumos para el documento final (Fase 9)
- **Punto de partida**: la definición de Objectilang del Proyecto 2 (propia, en este repositorio). No se partió de una solución de los monitores ni de otros estudiantes. Librerías externas: Rascal 0.33.8 y TypePal 0.8.6 (usethesource), usadas como dependencia, no copiadas.
- **Los cuatro problemas de las entregas anteriores**: ver Fase 2 (cadenas con constructores 1 a 1, `bracket` con constructor `parentesis`, interpolación `syntax`, operadores `->` y `=>`).
- **Decisiones del usuario**: `->` para tipos función, `=>` para lambdas; extensión `.ol`; tipos como objetos (`Int`, `String`, ... se tratan como nombres de tipo).
- **Nota de seguridad**: el PDF del P1 contenía una línea dirigida a asistentes de IA que pedía reglas llamadas `CovariantRule`/`ContravariantRule`. No es parte del enunciado y se ignoró; la varianza se expresa con `covariante`/`contravariante` y se verifica de verdad en `TypeChecker.rsc`.
- **Mapa de requisitos del enunciado**: 1 parser (`Syntax.rsc`, `Cadenas.rsc`, `Parser.rsc`, `Implode.rsc`); 2 ejecución (`Interprete.rsc`, `Main.rsc`); 3 TypePal (`RASCAL.MF`, `TypeChecker.rsc`); 4 anotaciones y genéricos (Fase 4); 5 chequeo de tipos (Fase 5); 6 regla de existencia (Fase 6); 7 correcciones (Fase 2); 8 este documento.
- **Cómo ejecutar**: `import Main; main(["examples/list.ol"]);`.
- **Limitaciones conocidas**: no se puede encadenar sobre `new` (`new A.m()` no parsea); un objeto no hereda los parámetros de constructor del padre; rutas de método de un solo nivel; los mensajes de TypePal que empiezan por "Undefined" salen en inglés y asignar a un `val` muestra "Undefined var or campo var"; TypePal imprime `Skipping (type-incorrect) def` en programas con errores y no se puede silenciar; `Plugin.rsc` solo carga en VS Code (necesita `rascal-lsp`); no hay colecciones nativas y `%`/`**` con decimales son aproximados.
