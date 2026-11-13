module Cadenas

syntax Cadena = cadenaLiteral: "\"" ParteCadena* partes "\"";

syntax ParteCadena
  = parteTexto: TextoCadena texto
  | parteVariable: "$" Identificador nombre
  | parteExpresion: Interpolacion e
  ;

lexical TextoCadena = @category="Constant" ![\"$]+ !>> ![\"$];

syntax Caracter = caracterLiteral: "\'" CaracterSimple valor "\'";

lexical CaracterSimple = @category="Constant" ![\'\n];
