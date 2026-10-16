module Implode

import IO;
import ParseTree;
import Syntax;
import AST;
import Parser;

AstPrograma construirAst(start[S] arbol) = implode(#AstPrograma, arbol.top);

AstPrograma desdeTexto(str texto) = construirAst(parsearTexto(texto));

AstPrograma cargar(loc archivo) = construirAst(parsearArchivo(archivo));

void checkAst() {
  for (loc f <- |project://proyecto-2-lym/examples|.ls, f.extension == "obj") {
    cargar(f);
    println("AST OK    <f.file>");
  }
}
