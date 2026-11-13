module Plugin

import ParseTree;
import util::LanguageServer;
import util::Reflective;
import Parser;

Tree parsear(str entrada, loc origen) = parsearTexto(entrada, origen);

set[LanguageService] objectilangContributions() = {
  parsing(parsear)
};

void main() {
  registerLanguage(
    language(
      getProjectPathConfig(|project://proyecto-2-lym|),
      "Objectilang",
      {"ol"},
      "Plugin",
      "objectilangContributions"
    )
  );
}
