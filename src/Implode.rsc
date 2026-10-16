module Implode

import IO;
import String;
import ParseTree;
import Syntax;
import AST;
import Parser;

AstPrograma construirAst(start[S] arbol) = estructurarCadenas(implode(#AstPrograma, arbol.top));

AstPrograma desdeTexto(str texto) = construirAst(parsearTexto(texto));

AstPrograma cargar(loc archivo) = construirAst(parsearArchivo(archivo));

AstExpresion expresionDesdeTexto(str texto) =
  estructurarCadenas(implode(#AstExpresion, parse(#Expresion, trim(texto))));

AstPrograma estructurarCadenas(AstPrograma ast) =
  visit (ast) { case cadena(str c) => cadenaCompuesta(partesCadena(c)) };

AstExpresion estructurarCadenas(AstExpresion ast) =
  visit (ast) { case cadena(str c) => cadenaCompuesta(partesCadena(c)) };

list[AstParteCadena] partesCadena(str c) {
  str s = substring(c, 1, size(c) - 1);
  list[AstParteCadena] partes = [];
  str acumulado = "";
  int i = 0;
  while (i < size(s)) {
    str ch = substring(s, i, i + 1);
    if (ch == "$" && i + 1 < size(s) && substring(s, i + 1, i + 2) == "{") {
      int fin = i + 2;
      int nivel = 1;
      while (fin < size(s) && nivel > 0) {
        str x = substring(s, fin, fin + 1);
        if (x == "{") nivel += 1;
        if (x == "}") nivel -= 1;
        fin += 1;
      }
      if (acumulado != "") {
        partes += [parteTexto(acumulado)];
        acumulado = "";
      }
      partes += [parteExpresion(expresionDesdeTexto(substring(s, i + 2, fin - 1)))];
      i = fin;
    }
    else if (ch == "$") {
      int fin = i + 1;
      while (fin < size(s) && /^[a-zA-Z0-9]$/ := substring(s, fin, fin + 1)) {
        fin += 1;
      }
      if (acumulado != "") {
        partes += [parteTexto(acumulado)];
        acumulado = "";
      }
      partes += [parteVariable(substring(s, i + 1, fin))];
      i = fin;
    }
    else {
      acumulado += ch;
      i += 1;
    }
  }
  if (acumulado != "") {
    partes += [parteTexto(acumulado)];
  }
  return partes;
}

void checkAst() {
  for (loc f <- |project://proyecto-2-lym/examples|.ls, f.extension == "obj") {
    cargar(f);
    println("AST OK    <f.file>");
  }
}