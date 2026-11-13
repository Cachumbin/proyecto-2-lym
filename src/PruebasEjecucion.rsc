module PruebasEjecucion

import Interprete;

private str salidaDe(str nombre) = ejecutarArchivo(|project://proyecto-2-lym/examples/ejecucion/<nombre>.ol|);

test bool aritmetica() = salidaDe("aritmetica") ==
  "suma 9\ndivision 3\nmodulo 1\npotencia 1024\ndecimal 7.5\nprecedencia 9\nnegado -7\ncomparacion true\n";

test bool variables() = salidaDe("variables") == "contador=10 letra=z\nmaximo 10\n";

test bool objetos() = salidaDe("objetos") == "caja 42\nguau x3\nDog\ncuenta 5\n";

test bool lambdas() = salidaDe("lambdas") == "2\n5\ndoblando 21\n42\n";

test bool sobrescritura() = salidaDe("override") == "hola mundo\n";

test bool ejemploListaDelEnunciado() =
  ejecutarArchivo(|project://proyecto-2-lym/examples/list.ol|) == "Print the line of animal dogs: Dog";

test bool ejemploTransformerDelEnunciado() =
  ejecutarArchivo(|project://proyecto-2-lym/examples/transformer.ol|)
    == "Preparing specialized food for an animal...\nResulting food type: DogFood";

test bool divisionPorCeroEsErrorDeEjecucion() {
  try {
    ejecutarTexto("method main {\n  println(1 / 0)\n}");
  } catch errorEjecucion(_): return true;
  return false;
}

test bool variableInexistenteEsErrorDeEjecucion() {
  try {
    ejecutarTexto("method main {\n  println(x)\n}");
  } catch errorEjecucion(_): return true;
  return false;
}
