module PruebasPipeline

import IO;
import List;
import Message;
import ParseTree;
import Parser;
import String;
import Implode;
import TypeChecker;
import Interprete;

loc raiz = |project://proyecto-2-lym/examples|;

list[loc] validos = [raiz + "list.ol", raiz + "transformer.ol", raiz + "tipos.ol",
                     raiz + "tipado/validos/basico.ol", raiz + "tipado/validos/existencia.ol"]
                  + [f | loc f <- (raiz + "ejecucion").ls, f.extension == "ol"];

list[loc] invalidosDeSintaxis = [f | loc f <- (raiz + "invalidos").ls, f.extension == "ol"];

list[loc] invalidosDeTipos = [f | loc f <- (raiz + "tipado/invalidos").ls, f.extension == "ol"];

bool parsea(loc f) {
  try {
    parsearArchivo(f);
    return true;
  } catch ParseError(_): return false;
}

test bool validosParsean() = all(f <- validos, parsea(f));

test bool validosGeneranAst() = all(f <- validos, cargar(f) is programa);

test bool validosTipan() = all(f <- validos, isEmpty(erroresDeArchivo(f)));

test bool validosSeEjecutan() = all(f <- validos, size(ejecutarArchivo(f)) >= 0);

test bool invalidosDeSintaxisNoParsean() = all(f <- invalidosDeSintaxis, !parsea(f));

test bool invalidosDeTiposParsean() = all(f <- invalidosDeTipos, parsea(f));

test bool invalidosDeTiposFallanEnTipos() = all(f <- invalidosDeTipos, !isEmpty(erroresDeArchivo(f)));

test bool mainRechazaProgramasInvalidos() = all(f <- invalidosDeTipos, !ejecutarSiTipa(f));

bool ejecutarSiTipa(loc f) {
  if (!isEmpty(erroresDeArchivo(f))) return false;
  ejecutarArchivo(f);
  return true;
}
