module Parser

import ParseTree;
import Syntax;

start[S] parsearTexto(str texto, loc origen) = parse(#start[S], texto, origen);

start[S] parsearTexto(str texto) = parse(#start[S], texto);

start[S] parsearArchivo(loc archivo) = parse(#start[S], archivo);
