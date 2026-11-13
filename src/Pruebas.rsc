module Pruebas

import ParseTree;
import Parser;
import Implode;
import AST;

list[loc] ejemplos(str carpeta) =
  [f | loc f <- (|project://proyecto-2-lym/examples| + carpeta).ls, f.extension == "ol"];

list[loc] validos() = [f | loc f <- |project://proyecto-2-lym/examples|.ls, f.extension == "ol"];

list[loc] invalidos() = ejemplos("invalidos");

bool parsea(loc archivo) {
  try {
    parsearArchivo(archivo);
    return true;
  }
  catch ParseError(_): return false;
}

test bool validosParsean() = all(loc f <- validos(), parsea(f));

test bool validosTienenAst() = all(loc f <- validos(), programa(_) := cargar(f));

test bool invalidosFallan() = all(loc f <- invalidos(), !parsea(f));

test bool interpolacionConEspacios() =
  programa([valDeclaracion("s", [], [cadena(cadenaLiteral([
    parteTexto("a "),
    parteExpresion(ruta(variable("x"))),
    parteTexto(" b")
  ]))])]) := desdeTexto("val s = \"a ${ x } b\"");

test bool interpolacionDeVariable() =
  programa([valDeclaracion("s", [], [cadena(cadenaLiteral([
    parteTexto("Hola "),
    parteVariable("nombre"),
    parteTexto("!")
  ]))])]) := desdeTexto("val s = \"Hola $nombre!\"");

test bool cadenaVacia() =
  programa([valDeclaracion("s", [], [cadena(cadenaLiteral([]))])]) := desdeTexto("val s = \"\"");

test bool espaciosDelTextoSeConservan() =
  programa([valDeclaracion("s", [], [cadena(cadenaLiteral([parteTexto("  a  ")]))])]) :=
    desdeTexto("val s = \"  a  \"");

test bool parentesisEnAst() =
  programa([valDeclaracion("a", [], [multiplicacion(
    parentesis(suma(entero(1), entero(2))), entero(3))])]) := desdeTexto("val a = (1 + 2) * 3");

test bool precedenciaAritmetica() =
  programa([valDeclaracion("a", [], [suma(entero(1), multiplicacion(entero(2), entero(3)))])]) :=
    desdeTexto("val a = 1 + 2 * 3");

test bool tipoFuncionEnAst() =
  programa([valDeclaracion("f", [tipoFuncion([objeto("Int", [])], objeto("Int", []))], [])]) :=
    desdeTexto("val f: (Int) -\> Int");

test bool tipoFuncionDentroDeGenerico() =
  programa([valDeclaracion("l", [objeto("List", [tipoFuncion([objeto("Int", [])], objeto("Int", []))])], [])]) :=
    desdeTexto("val l: List[(Int) -\> Int]");

test bool lambdaDeExpresion() =
  programa([valDeclaracion("f", [], [lambda(
    [parametroMetodo("x", objeto("Int", []))],
    suma(ruta(variable("x")), entero(1)))])]) := desdeTexto("val f = (x: Int) =\> x + 1");

test bool lambdaDeBloque() =
  programa([valDeclaracion("f", [], [lambdaBloque(
    [parametroMetodo("x", objeto("Int", []))],
    bloque([instruccionExpresion(ruta(variable("x")))]))])]) := desdeTexto("val f = (x: Int) =\> { x }");

test bool condicionalSinAmbiguedad() =
  programa([valDeclaracion("e", [], [condicional(
    ruta(variable("a")),
    cuerpoExpresion(ruta(variable("b"))),
    suma(ruta(variable("c")), entero(1)))])]) := desdeTexto("val e = if a then b else c + 1");

test bool caracterEnAst() =
  programa([valDeclaracion("c", [objeto("Char", [])], [caracter(caracterLiteral("a"))])]) :=
    desdeTexto("val c: Char = \'a\'");

test bool tiposAnotadosEnAst() =
  programa([valDeclaracion("c", [objeto("Caja", [objeto("Int", [])])], [
    instanciacion(instanciacionConArgumentos(objeto("Caja", [objeto("Int", [])]), [entero(1)], []))])]) :=
    desdeTexto("val c: Caja[Int] = new Caja[Int](1)");
