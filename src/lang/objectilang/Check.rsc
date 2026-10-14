module lang::objectilang::Check

import IO;
import ParseTree;
import lang::objectilang::Syntax;

// Parsea cada archivo .obj de la carpeta examples y dice cuáles fallan.
// Uso en la terminal de Rascal:
//   import lang::objectilang::Check;
//   checkExamples();
void checkExamples() {
  for (loc f <- |project://proyecto-2-lym/examples|.ls, f.extension == "obj") {
    try {
      parse(#start[Program], f);
      println("OK        <f.file>");
    }
    catch ParseError(loc l): {
      println("ERROR     <f.file> (línea <l.begin.line>, columna <l.begin.column>)");
    }
    catch Ambiguity(loc l, str nt, str s): {
      println("AMBIGUO   <f.file> (línea <l.begin.line>, regla <nt>)");
    }
  }
}
