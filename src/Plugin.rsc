module Plugin

import ParseTree;
import util::LanguageServer;
import util::Reflective;
import Syntax;

// Servicio de parseo: recibe el texto de un archivo y devuelve su árbol.
// Con esto el editor resalta la sintaxis y marca los errores de parseo.
Tree parsear(str entrada, loc origen) = parse(#start[S], entrada, origen);

// Se escribe parser(parsear) y no parser(#start[S]): ParseTree también define
// una función llamada parser, y con un tipo como argumento Rascal elige esa.
set[LanguageService] objectilangContributions() = {
  parser(parsear)
};

// Se ejecuta una vez en la terminal de Rascal:
//   import Plugin;
//   main();
void main() {
  registerLanguage(
    language(
      getProjectPathConfig(|project://proyecto-2-lym|),
      "Objectilang",
      "obj",
      "Plugin",
      "objectilangContributions"
    )
  );
}
