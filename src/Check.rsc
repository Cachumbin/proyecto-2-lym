module Check

import IO;
import ParseTree;
import Parser;

void checkExamples() {
  for (loc f <- |project://proyecto-2-lym/examples|.ls, f.extension == "ol") {
    try {
      parsearArchivo(f);
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
