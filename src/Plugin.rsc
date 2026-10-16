module Plugin

import ParseTree;
import util::LanguageServer;
import util::Reflective;
import Syntax;

// Servicio de parseo: recibe el texto de un archivo y devuelve su árbol.
// Con esto el editor resalta la sintaxis y marca los errores de parseo.
Tree parsear(str entrada, loc origen) = parse(#start[S], entrada, origen);

set[LanguageService] objectilangContributions() = {
  parsing(parsear)
};

// Se ejecuta una vez en la terminal de Rascal:
//   import Plugin;
//   main();
void main() {
  registerLanguage(
    language(
      getProjectPathConfig(|project://proyecto-2-lym|),
      "Objectilang",
      {"obj"},
      "Plugin",
      "objectilangContributions"
    )
  );
}
