module Main

import IO;
import List;
import Message;
import ParseTree;
import Parser;
import Implode;
import TypeChecker;
import Interprete;
import AST;

bool ejecutar(loc archivo) {
  start[S] arbol;
  try {
    arbol = parsearArchivo(archivo);
  } catch ParseError(loc donde): {
    println("Error de sintaxis en <archivo.file>, línea <donde.begin.line>, columna <donde.begin.column>");
    return false;
  }

  list[Message] errores = [m | m <- modeloDeTipos(arbol).messages, m is error];
  if (!isEmpty(errores)) {
    for (error(mensaje, donde) <- errores) {
      println("Error de tipos en <archivo.file>, línea <donde.begin.line>: <mensaje>");
    }
    return false;
  }

  try {
    ejecutarAst(construirAst(arbol), true);
  } catch errorEjecucion(str mensaje): {
    println("Error de ejecución: <mensaje>");
    return false;
  }
  return true;
}

void main(list[str] argumentos) {
  if (isEmpty(argumentos)) {
    println("Uso: main([\"ruta/al/programa.ol\"])");
    return;
  }
  ejecutar(|cwd:///| + argumentos[0]);
}
