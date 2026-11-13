module TypeChecker

import List;
import Message;
import ParseTree;
import Syntax;
import Cadenas;
import Parser;
extend analysis::typepal::TypePal;

data Varianza
  = varianzaCo()
  | varianzaContra()
  | varianzaInv()
  ;

data AType
  = tipoEntero()
  | tipoDecimal()
  | tipoBooleano()
  | tipoCaracter()
  | tipoCadena()
  | tipoUnidad()
  | tipoImpresion()
  | tipoParametro(str nombre, Varianza varianza)
  | tipoInstancia(str nombre, list[AType] argumentos, list[AType] parametros, list[AType] padres)
  | tipoFlecha(list[AType] entradas, AType salida)
  ;

data IdRole
  = objetoId()
  | constructorId()
  | valId()
  | varId()
  | campoValId()
  | campoVarId()
  | metodoId()
  | tipoParametroId()
  ;

data PathRole = miembrosPath();

set[IdRole] lecturas = {valId(), varId(), campoValId(), campoVarId(), metodoId()};

set[IdRole] escrituras = {varId(), campoVarId()};

AType tipoClase = tipoInstancia("Class", [], [], []);

set[str] tiposPrimitivos = {"Int", "Decimal", "Boolean", "Char", "String"};

map[str, str] operadoresAritmeticos = (
  "suma": "+",
  "resta": "-",
  "multiplicacion": "*",
  "division": "/",
  "modulo": "%",
  "potencia": "**"
);

map[str, str] operadoresOrden = (
  "menor": "\<",
  "mayor": "\>",
  "menorIgual": "\<=",
  "mayorIgual": "\>="
);

map[str, str] operadoresLogicos = (
  "conjuncion": "and",
  "disyuncion": "or"
);

map[str, str] operadoresIgualdad = (
  "igual": "=",
  "distinto": "\<\>"
);

str prettyAType(tipoEntero()) = "Int";
str prettyAType(tipoDecimal()) = "Decimal";
str prettyAType(tipoBooleano()) = "Boolean";
str prettyAType(tipoCaracter()) = "Char";
str prettyAType(tipoCadena()) = "String";
str prettyAType(tipoUnidad()) = "Unit";
str prettyAType(tipoImpresion()) = "print";
str prettyAType(tipoParametro(str nombre, _)) = nombre;
str prettyAType(tipoFlecha(list[AType] entradas, AType salida)) =
  "(<intercalate(", ", [prettyAType(e) | e <- entradas])>) -\> <prettyAType(salida)>";
str prettyAType(tipoInstancia(str nombre, list[AType] argumentos, _, _)) =
  isEmpty(argumentos) ? nombre : "<nombre>[<intercalate(", ", [prettyAType(a) | a <- argumentos])>]";

list[Tree] hijos(Tree arbol) = arbol.args;

Expresion expresionDe(Instruccion instruccion) = [e | Expresion e <- hijos(instruccion)][0];

str nombreConstructor(str objeto) = "\<constructor:<objeto>\>";

str etiqueta(Tree arbol) = arbol.prod.def.name;

bool esNumerico(AType tipo) = tipo == tipoEntero() || tipo == tipoDecimal();

Varianza varianzaDe(ParametroDefinicion parametro) =
  parametro is covariante ? varianzaCo() : parametro is contravariante ? varianzaContra() : varianzaInv();

list[ParametroDefinicion] parametrosDefinicion(ObjetoCreador objeto) =
  [p | ParametrosDefinicion g <- hijos(objeto.genericos), ParametroDefinicion p <- g.parametros];

list[ParametroConstructor] camposConstructor(ObjetoCreador objeto) =
  [p | Constructor k <- hijos(objeto.constructor), ParametroConstructor p <- k.parametros];

list[Objeto] extensiones(ObjetoCreador objeto) = [e.ob | Extiende e <- hijos(objeto.extiende)];

list[Objeto] argumentosDeTipo(Objeto tipo) =
  [a | ParametrosUso p <- hijos(tipo.parametros), Objeto a <- p.objetos];

list[Objeto] anotacion(Tree opcional) = [a.ob | AnotacionTipo a <- hijos(opcional)];

list[Bloque] cuerpoDeMetodo(Tree opcional) = [m.b | CuerpoMetodo m <- hijos(opcional)];

list[Bloque] bloqueOpcional(Tree opcional) = [b | Bloque b <- hijos(opcional)];

list[Expresion] valorOpcional(Tree opcional) = [i.valor | Inicializacion i <- hijos(opcional)];

bool esSubtipo(AType a, AType b) {
  if (a == b) return true;
  switch (<a, b>) {
    case <tipoEntero(), tipoDecimal()>:
      return true;
    case <tipoInstancia(str n1, list[AType] args1, list[AType] ps1, list[AType] padres1), tipoInstancia(str n2, list[AType] args2, _, _)>: {
      if (n1 == n2) {
        return size(args1) == size(args2)
          && all(i <- index(args1), argumentoCompatible(ps1[i], args1[i], args2[i]));
      }
      return any(p <- padres1, esSubtipo(p, b));
    }
    case <tipoFlecha(list[AType] e1, AType s1), tipoFlecha(list[AType] e2, AType s2)>:
      return size(e1) == size(e2) && all(i <- index(e1), esSubtipo(e2[i], e1[i])) && esSubtipo(s1, s2);
  }
  return false;
}

bool argumentoCompatible(tipoParametro(_, varianzaCo()), AType a, AType b) = esSubtipo(a, b);
bool argumentoCompatible(tipoParametro(_, varianzaContra()), AType a, AType b) = esSubtipo(b, a);
default bool argumentoCompatible(AType _, AType a, AType b) = a == b;

AType sustituir(AType tipo, map[str, AType] ligas) {
  switch (tipo) {
    case tipoParametro(str nombre, _):
      return ligas[nombre] ? tipo;
    case tipoInstancia(str nombre, list[AType] argumentos, list[AType] parametros, list[AType] padres):
      return tipoInstancia(nombre, [sustituir(a, ligas) | a <- argumentos], parametros, [sustituir(p, ligas) | p <- padres]);
    case tipoFlecha(list[AType] entradas, AType salida):
      return tipoFlecha([sustituir(e, ligas) | e <- entradas], sustituir(salida, ligas));
  }
  return tipo;
}

map[str, AType] ligar(list[AType] parametros, list[AType] argumentos) =
  (nombre: argumentos[i] | i <- index(parametros), i < size(argumentos), tipoParametro(str nombre, _) := parametros[i]);

AType instanciar(tipoInstancia(str nombre, _, list[AType] parametros, list[AType] padres), list[AType] argumentos) =
  tipoInstancia(nombre, argumentos, parametros, [sustituir(p, ligar(parametros, argumentos)) | p <- padres]);

map[str, AType] ligadura(AType receptor) {
  map[str, AType] ligas = ();
  if (tipoInstancia(_, list[AType] argumentos, list[AType] parametros, list[AType] padres) := receptor) {
    for (p <- padres) ligas += ligadura(p);
    ligas += ligar(parametros, argumentos);
  }
  return ligas;
}

AType tipoDeMiembro(AType receptor, AType declarado) = sustituir(declarado, ligadura(receptor));

list[AType] ascendientes(AType tipo) {
  list[AType] resultado = [tipo];
  if (tipoInstancia(_, _, _, list[AType] padres) := tipo) {
    for (p <- padres) resultado += ascendientes(p);
  }
  return resultado;
}

AType unir(AType a, AType b, Tree donde, Solver s) {
  if (esSubtipo(a, b)) return b;
  if (esSubtipo(b, a)) return a;
  for (p <- ascendientes(a), esSubtipo(b, p)) return p;
  s.report(error(donde, "Las ramas tienen tipos incompatibles: %t y %t", a, b));
  return a;
}

map[str, AType] unificar(AType formal, AType concreto, map[str, AType] ligas) {
  switch (formal) {
    case tipoParametro(str nombre, _): {
      if (nombre in ligas) {
        if (esSubtipo(ligas[nombre], concreto)) ligas[nombre] = concreto;
      } else {
        ligas[nombre] = concreto;
      }
    }
    case tipoInstancia(str nombre, list[AType] formales, _, _): {
      if (tipoInstancia(nombre, list[AType] reales, _, _) := concreto && size(formales) == size(reales)) {
        for (i <- index(formales)) ligas = unificar(formales[i], reales[i], ligas);
      }
    }
    case tipoFlecha(list[AType] entradasFormales, AType salidaFormal): {
      if (tipoFlecha(list[AType] entradasReales, AType salidaReal) := concreto && size(entradasFormales) == size(entradasReales)) {
        for (i <- index(entradasFormales)) ligas = unificar(entradasFormales[i], entradasReales[i], ligas);
        ligas = unificar(salidaFormal, salidaReal, ligas);
      }
    }
  }
  return ligas;
}

AType instanciarDefinicion(AType definicion, list[AType] argumentos, Tree donde, Solver s) {
  switch (definicion) {
    case tipoParametro(_, _): {
      if (!isEmpty(argumentos)) s.report(error(donde, "El parámetro de tipo %t no recibe argumentos", definicion));
      return definicion;
    }
    case tipoInstancia(str nombre, _, list[AType] parametros, _): {
      if (size(argumentos) != size(parametros)) {
        s.report(error(donde, "El objeto %q espera %v argumentos de tipo pero recibió %v", nombre, size(parametros), size(argumentos)));
        return definicion;
      }
      return instanciar(definicion, argumentos);
    }
  }
  s.report(error(donde, "%t no es un tipo de objeto", definicion));
  return definicion;
}

tuple[list[str] typeNames, set[IdRole] idRoles] nombresDeTipo(tipoInstancia(str nombre, _, _, _)) = <[nombre], {objetoId()}>;
default tuple[list[str] typeNames, set[IdRole] idRoles] nombresDeTipo(AType _) = <[], {}>;

TypePalConfig configuracion() = tconfig(
  isSubType = esSubtipo,
  getTypeNamesAndRole = nombresDeTipo
);

void inicializar(Tree _, Collector c) {
  c.predefine("print", metodoId(), |global-scope:///|, defType(tipoImpresion()));
  c.predefine("println", metodoId(), |global-scope:///|, defType(tipoImpresion()));
}

TModel modeloDeTipos(Tree arbol) {
  if (arbol has top) arbol = arbol.top;
  Collector c = newCollector("objectilang", arbol, configuracion());
  inicializar(arbol, c);
  collect(arbol, c);
  return newSolver(arbol, c.run()).run();
}

list[Message] verificarTexto(str texto) = modeloDeTipos(parsearTexto(texto)).messages;

list[Message] verificarArchivo(loc archivo) = modeloDeTipos(parsearArchivo(archivo)).messages;

list[Message] erroresDeTexto(str texto) = [m | m <- verificarTexto(texto), m is error];

list[Message] erroresDeArchivo(loc archivo) = [m | m <- verificarArchivo(archivo), m is error];

list[ObjetoCreador] objetosDe(Tree arbol) {
  list[ObjetoCreador] encontrados = [];
  if (ObjetoCreador objeto := arbol) encontrados += [objeto];
  if (arbol has args) {
    for (Tree hijo <- arbol.args) encontrados += objetosDe(hijo);
  }
  return encontrados;
}

void collect(S current, Collector c) {
  for (ObjetoCreador objeto <- objetosDe(current)) {
    str nombre = "<objeto.nombre>";
    loc alcance = getLoc(objeto);
    c.push("objetos", <nombre, alcance>);
  }
  collect(current.instrucciones, c);
}

void colectarInstruccionExpresion(Instruccion current, Collector c) {
  collect(expresionDe(current), c);
}

void collect(ObjetoCreador current, Collector c) {
  str nombre = "<current.nombre>";
  list[ParametroDefinicion] parametros = parametrosDefinicion(current);
  list[AType] declarados = [tipoParametro("<p.nombre>", varianzaDe(p)) | p <- parametros];
  list[Objeto] extensionesDeclaradas = extensiones(current);
  list[Objeto] extiende = [e | e <- extensionesDeclaradas, e is objeto];
  list[ParametroConstructor] campos = camposConstructor(current);

  if (isEmpty(extiende)) {
    c.define(nombre, objetoId(), current, defType(tipoInstancia(nombre, declarados, declarados, [])));
  } else {
    Objeto padre = extiende[0];
    c.define(nombre, objetoId(), current, defType([padre.nombre] + argumentosDeTipo(padre), AType(Solver s) {
      AType definicionPadre = s.getType(padre.nombre);
      AType instancia = instanciarDefinicion(definicionPadre, [s.getType(a) | a <- argumentosDeTipo(padre)], padre, s);
      if (!(instancia is tipoInstancia)) {
        s.report(error(padre, "Un objeto solo puede extender otro objeto, no %t", instancia));
        return tipoInstancia(nombre, declarados, declarados, []);
      }
      return tipoInstancia(nombre, declarados, declarados, [instancia]);
    }));
  }

  c.enterScope(current);
    for (p <- parametros) {
      c.define("<p.nombre>", tipoParametroId(), p.nombre, defType(tipoParametro("<p.nombre>", varianzaDe(p))));
    }
    for (padre <- extiende) {
      c.addPathToDef(padre.nombre, {objetoId()}, miembrosPath());
      collect(argumentosDeTipo(padre), c);
    }
    for (padre <- extensionesDeclaradas, !(padre is objeto)) {
      c.report(error(padre, "Un objeto no puede extender un tipo función"));
    }
    collect(campos, c);
    list[Tree] tiposCampos = [p.tipo.ob | p <- campos];
    c.define(nombreConstructor(nombre), constructorId(), current.nombre, defType([current] + tiposCampos, AType(Solver s) {
      return tipoFlecha([s.getType(t) | t <- tiposCampos], s.getType(current));
    }));
  c.leaveScope(current);
}

void collect(ParametroConstructor current, Collector c) {
  Objeto tipo = current.tipo.ob;
  IdRole rol = current is parametroVal ? campoValId() : campoVarId();
  c.define("<current.nombre>", rol, current.nombre, defType(tipo));
  c.fact(current, tipo);
  collect(tipo, c);
  c.require("varianza del campo", current, [tipo], void(Solver s) {
    AType declarado = s.getType(tipo);
    if (declarado is tipoParametro) {
      if (declarado.varianza == varianzaContra()) {
        s.report(error(current, "El parámetro contravariante %t no puede usarse en el tipo de un campo", declarado));
      } else if (current is parametroVar && declarado.varianza == varianzaCo()) {
        s.report(error(current, "El parámetro covariante %t no puede usarse en el tipo de un campo var", declarado));
      }
    }
  });
}

void collect(ParametroMetodo current, Collector c) {
  Objeto tipo = current.tipo.ob;
  c.define("<current.nombre>", valId(), current.nombre, defType(tipo));
  c.fact(current, tipo);
  collect(tipo, c);
}

void colectarObjeto(Objeto current, Collector c) {
  list[Objeto] argumentos = argumentosDeTipo(current);
  str nombre = "<current.nombre>";
  if (nombre in tiposPrimitivos) {
    if (!isEmpty(argumentos)) c.report(error(current, "El tipo %q no recibe argumentos de tipo", nombre));
    c.fact(current, primitivo(nombre));
    return;
  }
  c.use(current.nombre, {objetoId(), tipoParametroId()});
  collect(argumentos, c);
  c.calculate("tipo de objeto", current, [current.nombre] + argumentos, AType(Solver s) {
    return instanciarDefinicion(s.getType(current.nombre), [s.getType(a) | a <- argumentos], current, s);
  });
}

void colectarTipoFuncion(Objeto current, Collector c) {
  list[Objeto] entradas = [p | p <- current.parametros];
  collect(entradas, c);
  collect(current.resultado, c);
  c.calculate("tipo función", current, entradas + [current.resultado], AType(Solver s) {
    return tipoFlecha([s.getType(e) | e <- entradas], s.getType(current.resultado));
  });
}

AType primitivo("Int") = tipoEntero();
AType primitivo("Decimal") = tipoDecimal();
AType primitivo("Boolean") = tipoBooleano();
AType primitivo("Char") = tipoCaracter();
AType primitivo("String") = tipoCadena();

void collect(VariableDeclaracion current, Collector c) {
  IdRole rol = current is valDeclaracion ? valId() : varId();
  list[Objeto] tipos = anotacion(current.tipo);
  list[Expresion] valores = valorOpcional(current.valor);

  if (!isEmpty(tipos)) {
    c.define("<current.nombre>", rol, current.nombre, defType(tipos[0]));
    collect(tipos[0], c);
    if (!isEmpty(valores)) {
      collect(valores[0], c);
      c.requireSubType(valores[0], tipos[0],
        error(valores[0], "Se esperaba un valor de tipo %t pero la expresión tiene tipo %t", tipos[0], valores[0]));
    }
  } else if (!isEmpty(valores)) {
    c.define("<current.nombre>", rol, current.nombre, defType(valores[0]));
    collect(valores[0], c);
  } else {
    c.report(error(current, "La declaración de %q necesita un tipo o un valor inicial", "<current.nombre>"));
    c.define("<current.nombre>", rol, current.nombre, defType(tipoUnidad()));
  }
}

void collect(VariableAsignacion current, Collector c) {
  collectarRuta(current.destino, escrituras, c);
  collect(current.valor, c);
  c.requireSubType(current.valor, current.destino,
    error(current.valor, "No se puede asignar un valor de tipo %t a un destino de tipo %t", current.valor, current.destino));
}

void collect(MetodoPrincipal current, Collector c) {
  collect(current.b, c);
}

void collect(MetodoExterno current, Collector c) {
  list[Identificador] ruta = [r | r <- current.ruta];
  list[ParametroMetodo] parametros = [p | p <- current.parametros];
  list[Objeto] retorno = anotacion(current.tipo);
  list[Bloque] cuerpo = cuerpoDeMetodo(current.cuerpo);
  list[Tree] dependencias = parametros + retorno;

  if (size(ruta) != 1) {
    c.report(error(current, "Solo se soportan rutas de método de un nivel (Objeto.metodo)"));
  }

  for (<str nombre, loc alcance> <- [t | tuple[str, loc] t <- c.getStack("objetos")], nombre == "<current.nombre>") {
    c.defineInScope(alcance, "<ruta[0]>", metodoId(), ruta[0], defType(dependencias, AType(Solver s) {
      return tipoFlecha([s.getType(p) | p <- parametros], isEmpty(retorno) ? tipoUnidad() : s.getType(retorno[0]));
    }));
    break;
  }

  c.enterScope(current);
    c.addPathToDef(current.nombre, {objetoId()}, miembrosPath());
    collect(parametros, c);
    collect(retorno, c);
    c.require("varianza del método", current, dependencias, void(Solver s) {
      for (p <- parametros) {
        AType declarado = s.getType(p);
        if (declarado is tipoParametro && declarado.varianza == varianzaCo()) {
          s.report(error(p, "El parámetro covariante %t no puede aparecer como parámetro de método", declarado));
        }
      }
      for (r <- retorno) {
        AType declarado = s.getType(r);
        if (declarado is tipoParametro && declarado.varianza == varianzaContra()) {
          s.report(error(r, "El parámetro contravariante %t no puede aparecer como tipo de retorno", declarado));
        }
      }
    });
    for (b <- cuerpo) {
      collect(b, c);
      if (!isEmpty(retorno)) {
        c.requireSubType(b, retorno[0],
          error(b, "El cuerpo del método devuelve %t pero se declaró %t", b, retorno[0]));
      }
    }
  c.leaveScope(current);
}

void collect(MetodoOverride current, Collector c) {
  list[ParametroMetodo] parametros = [p | p <- current.parametros];
  list[Objeto] retorno = anotacion(current.tipo);
  list[value] instancias = c.getStack("instancia");

  c.enterScope(current);
    collect(parametros, c);
    collect(retorno, c);
    collect(current.b, c);
  c.leaveScope(current);

  if (isEmpty(instancias)) {
    c.report(error(current, "override solo puede usarse dentro de new Objeto { ... }"));
    return;
  }

  value ultimaInstancia = c.top("instancia");
  if (Tree instancia := ultimaInstancia) {
    comprobarOverride(current, instancia, parametros, retorno, c);
  }
}

void comprobarOverride(MetodoOverride current, Tree instancia, list[ParametroMetodo] parametros, list[Objeto] retorno, Collector c) {
  c.use(current.nombre, {metodoId()});
  c.require("override", current, [current.nombre, instancia] + parametros + retorno, void(Solver s) {
    AType esperado = tipoDeMiembro(s.getType(instancia), s.getType(current.nombre));
    if (!(esperado is tipoFlecha)) {
      s.report(error(current.nombre, "%q no es un método", "<current.nombre>"));
      return;
    }
    AType salida = isEmpty(retorno) ? esperado.salida : s.getType(retorno[0]);
    AType declarado = tipoFlecha([s.getType(p) | p <- parametros], salida);
    if (!esSubtipo(declarado, esperado)) {
      s.report(error(current, "La firma de override %t no es compatible con la del método %t", declarado, esperado));
    }
    AType cuerpo = s.getType(current.b);
    if (!esSubtipo(cuerpo, salida)) {
      s.report(error(current.b, "El cuerpo devuelve %t pero se esperaba %t", cuerpo, salida));
    }
  });
}

void collect(Ciclo current, Collector c) {
  list[Identificador] nombres = current.patron is patronVariable ? [current.patron.nombre] : [n | n <- current.patron.nombres];
  c.enterScope(current);
    collect(current.coleccion, c);
    for (i <- index(nombres)) {
      definirElemento(nombres[i], i, size(nombres), current.coleccion, c);
    }
    collect(current.cuerpo, c);
  c.leaveScope(current);
}

void definirElemento(Identificador nombre, int posicion, int total, Expresion coleccion, Collector c) {
  c.define("<nombre>", valId(), nombre, defType([coleccion], AType(Solver s) {
    AType tipo = s.getType(coleccion);
    if (tipoInstancia(_, list[AType] argumentos, _, _) := tipo && size(argumentos) >= total && size(argumentos) > 0) {
      return total == 1 ? argumentos[0] : argumentos[posicion];
    }
    s.report(error(nombre, "No se puede iterar con %v variables sobre un valor de tipo %t", total, tipo));
    return tipoUnidad();
  }));
}

void collect(Bloque current, Collector c) {
  c.enterScope(current);
    collect(current.instrucciones, c);
  c.leaveScope(current);
  list[Instruccion] instrucciones = [i | i <- current.instrucciones];
  if (!isEmpty(instrucciones) && last(instrucciones) is instruccionExpresion) {
    c.fact(current, expresionDe(last(instrucciones)));
  } else {
    c.fact(current, tipoUnidad());
  }
}

void colectarCuerpoBloque(Cuerpo current, Collector c) {
  collect(current.b, c);
  c.fact(current, current.b);
}

void colectarCuerpoExpresion(Cuerpo current, Collector c) {
  collect(current.e, c);
  c.fact(current, current.e);
}

void collectarRuta(RutaOVariable ruta, set[IdRole] roles, Collector c) {
  if (ruta is variable) {
    c.use(ruta.id, roles);
    c.fact(ruta, ruta.id);
  } else if (ruta is acceso && "<ruta.campo>" == "getClass") {
    collectarRuta(ruta.base, lecturas, c);
    c.calculate("getClass", ruta, [ruta.base], AType(Solver s) {
      AType receptor = s.getType(ruta.base);
      if (!(receptor is tipoInstancia)) s.report(error(ruta, "getClass solo existe en objetos, no en %t", receptor));
      return tipoClase;
    });
  } else if (ruta is acceso && "<ruta.campo>" == "getSimpleName") {
    collectarRuta(ruta.base, lecturas, c);
    c.calculate("getSimpleName", ruta, [ruta.base], AType(Solver s) {
      AType receptor = s.getType(ruta.base);
      if (receptor != tipoClase) s.report(error(ruta, "getSimpleName solo existe en el resultado de getClass, no en %t", receptor));
      return tipoCadena();
    });
  } else if (ruta is acceso) {
    collectarRuta(ruta.base, lecturas, c);
    c.useViaType(ruta.base, ruta.campo, roles);
    c.calculate("acceso a miembro", ruta, [ruta.base, ruta.campo], AType(Solver s) {
      return tipoDeMiembro(s.getType(ruta.base), s.getType(ruta.campo));
    });
  } else {
    list[Expresion] argumentos = [a | a <- ruta.argumentos];
    collectarRuta(ruta.base, lecturas, c);
    collect(argumentos, c);
    c.calculate("llamada", ruta, [ruta.base] + argumentos, AType(Solver s) {
      return tipoDeLlamada(ruta, s.getType(ruta.base), argumentos, s);
    });
  }
}

void collect(RutaOVariable current, Collector c) {
  collectarRuta(current, lecturas, c);
}

AType tipoDeLlamada(RutaOVariable ruta, AType funcion, list[Expresion] argumentos, Solver s) {
  switch (funcion) {
    case tipoImpresion():
      return isEmpty(argumentos) ? tipoUnidad() : s.getType(argumentos[0]);
    case tipoFlecha(list[AType] entradas, AType salida): {
      if (size(entradas) != size(argumentos)) {
        s.report(error(ruta, "Se esperaban %v argumentos pero se recibieron %v", size(entradas), size(argumentos)));
        return salida;
      }
      for (i <- index(argumentos)) {
        AType concreto = s.getType(argumentos[i]);
        if (!esSubtipo(concreto, entradas[i])) {
          s.report(error(argumentos[i], "El argumento tiene tipo %t pero el parámetro espera %t", concreto, entradas[i]));
        }
      }
      return salida;
    }
  }
  s.report(error(ruta, "No se puede llamar a un valor de tipo %t", funcion));
  return tipoUnidad();
}

void collect(Instanciacion current, Collector c) {
  Objeto ob = current.ob;
  list[Expresion] argumentos = current is instanciacionConArgumentos ? [a | a <- current.argumentos] : [];
  list[Bloque] cuerpo = bloqueOpcional(current.cuerpo);

  if (!(ob is objeto)) {
    c.report(error(ob, "No se puede instanciar un tipo función"));
    return;
  }

  list[Objeto] explicitos = argumentosDeTipo(ob);
  c.useQualified(["<ob.nombre>", nombreConstructor("<ob.nombre>")], ob, {constructorId()}, {objetoId()});
  collect(explicitos, c);
  collect(argumentos, c);
  c.calculate("instanciación", current, [ob] + explicitos + argumentos, AType(Solver s) {
    return tipoDeInstanciacion(current, s.getType(ob), [s.getType(e) | e <- explicitos], argumentos, s);
  });

  for (b <- cuerpo) {
    c.push("instancia", current);
    c.enterScope(b);
      c.addPathToDef(ob.nombre, {objetoId()}, miembrosPath());
      collect(b.instrucciones, c);
    c.leaveScope(b);
    c.pop("instancia");
  }
}

AType tipoDeInstanciacion(Instanciacion donde, AType constructor, list[AType] explicitos, list[Expresion] argumentos, Solver s) {
  if (!(constructor is tipoFlecha)) return constructor;
  list[AType] formales = constructor.entradas;
  AType definicion = constructor.salida;
  list[AType] parametros = definicion.parametros;

  if (!isEmpty(explicitos) && size(explicitos) != size(parametros)) {
    s.report(error(donde, "El objeto %q espera %v argumentos de tipo pero recibió %v", definicion.nombre, size(parametros), size(explicitos)));
    return definicion;
  }
  if (size(formales) != size(argumentos)) {
    s.report(error(donde, "El constructor de %q espera %v argumentos pero recibió %v", definicion.nombre, size(formales), size(argumentos)));
    return instanciar(definicion, isEmpty(explicitos) ? parametros : explicitos);
  }

  list[AType] reales = [s.getType(a) | a <- argumentos];
  map[str, AType] ligas = ();
  if (isEmpty(explicitos)) {
    for (i <- index(formales)) ligas = unificar(formales[i], reales[i], ligas);
  } else {
    ligas = ligar(parametros, explicitos);
  }

  list[AType] finales = [];
  for (p <- parametros) {
    if (tipoParametro(str nombre, _) := p, nombre in ligas) {
      finales += [ligas[nombre]];
    } else {
      s.report(error(donde, "No se pudo inferir el parámetro de tipo %t de %q; indícalo explícitamente", p, definicion.nombre));
      finales += [p];
    }
  }

  for (i <- index(argumentos)) {
    AType esperado = sustituir(formales[i], ligas);
    if (!esSubtipo(reales[i], esperado)) {
      s.report(error(argumentos[i], "El argumento tiene tipo %t pero el constructor espera %t", reales[i], esperado));
    }
  }
  return instanciar(definicion, finales);
}

void collect(ParteCadena current, Collector c) {
  if (current is parteVariable) {
    c.use(current.nombre, lecturas);
  } else if (current is parteExpresion) {
    collect(current.e.e, c);
  }
}

void collect(Cadena current, Collector c) {
  collect(current.partes, c);
}

void colectarEntero(Expresion current, Collector c) {
  c.fact(current, tipoEntero());
}

void colectarDecimal(Expresion current, Collector c) {
  c.fact(current, tipoDecimal());
}

void colectarBooleano(Expresion current, Collector c) {
  c.fact(current, tipoBooleano());
}

void colectarCadena(Expresion current, Collector c) {
  collect(current.c, c);
  c.fact(current, tipoCadena());
}

void colectarCaracter(Expresion current, Collector c) {
  c.fact(current, tipoCaracter());
}

void colectarRuta(Expresion current, Collector c) {
  collect(current.r, c);
  c.fact(current, current.r);
}

void colectarInstanciacion(Expresion current, Collector c) {
  collect(current.i, c);
  c.fact(current, current.i);
}

void colectarParentesis(Expresion current, Collector c) {
  collect(current.e, c);
  c.fact(current, current.e);
}

void colectarNegacion(Expresion current, Collector c) {
  collect(current.e, c);
  c.calculate("negación", current, [current.e], AType(Solver s) {
    AType tipo = s.getType(current.e);
    if (tipo == tipoBooleano() || esNumerico(tipo)) return tipo;
    s.report(error(current, "neg no está definido para %t", tipo));
    return tipoBooleano();
  });
}

void colectarOperadoresAritmeticos(Expresion current, Collector c) {
  str simbolo = operadoresAritmeticos[etiqueta(current)];
  collect(current.izq, current.der, c);
  c.calculate("operador <simbolo>", current, [current.izq, current.der], AType(Solver s) {
    AType izq = s.getType(current.izq);
    AType der = s.getType(current.der);
    if (simbolo == "+" && izq == tipoCadena() && der == tipoCadena()) return tipoCadena();
    if (esNumerico(izq) && esNumerico(der)) {
      return izq == tipoDecimal() || der == tipoDecimal() ? tipoDecimal() : tipoEntero();
    }
    s.report(error(current, "El operador %q no está definido para %t y %t", simbolo, izq, der));
    return tipoEntero();
  });
}

void colectarOperadoresOrden(Expresion current, Collector c) {
  str simbolo = operadoresOrden[etiqueta(current)];
  collect(current.izq, current.der, c);
  c.calculate("operador <simbolo>", current, [current.izq, current.der], AType(Solver s) {
    AType izq = s.getType(current.izq);
    AType der = s.getType(current.der);
    bool ordenables = (esNumerico(izq) && esNumerico(der))
      || (izq == der && (izq == tipoCaracter() || izq == tipoCadena()));
    if (!ordenables) s.report(error(current, "No se pueden comparar %t y %t con %q", izq, der, simbolo));
    return tipoBooleano();
  });
}

void colectarOperadoresIgualdad(Expresion current, Collector c) {
  str simbolo = operadoresIgualdad[etiqueta(current)];
  collect(current.izq, current.der, c);
  c.calculate("operador <simbolo>", current, [current.izq, current.der], AType(Solver s) {
    AType izq = s.getType(current.izq);
    AType der = s.getType(current.der);
    if (!(esSubtipo(izq, der) || esSubtipo(der, izq))) {
      s.report(error(current, "No se pueden comparar valores de tipos %t y %t", izq, der));
    }
    return tipoBooleano();
  });
}

void colectarOperadoresLogicos(Expresion current, Collector c) {
  str simbolo = operadoresLogicos[etiqueta(current)];
  collect(current.izq, current.der, c);
  c.calculate("operador <simbolo>", current, [current.izq, current.der], AType(Solver s) {
    AType izq = s.getType(current.izq);
    AType der = s.getType(current.der);
    if (izq != tipoBooleano() || der != tipoBooleano()) {
      s.report(error(current, "El operador %q requiere Boolean pero recibió %t y %t", simbolo, izq, der));
    }
    return tipoBooleano();
  });
}

void colectarCondicional(Expresion current, Collector c) {
  collect(current.condicion, current.entonces, current.sino, c);
  c.requireEqual(current.condicion, tipoBooleano(),
    error(current.condicion, "La condición debe ser Boolean pero tiene tipo %t", current.condicion));
  c.calculate("condicional", current, [current.entonces, current.sino], AType(Solver s) {
    return unir(s.getType(current.entonces), s.getType(current.sino), current, s);
  });
}

void colectarLambda(Expresion current, Collector c) {
  list[ParametroMetodo] parametros = [p | p <- current.parametros];
  c.enterScope(current);
    collect(parametros, c);
    collect(current.cuerpo, c);
  c.leaveScope(current);
  c.calculate("lambda", current, parametros + [current.cuerpo], AType(Solver s) {
    return tipoFlecha([s.getType(p) | p <- parametros], s.getType(current.cuerpo));
  });
}

void colectarLambdaBloque(Expresion current, Collector c) {
  list[ParametroMetodo] parametros = [p | p <- current.parametros];
  c.enterScope(current);
    collect(parametros, c);
    collect(current.b, c);
  c.leaveScope(current);
  c.calculate("lambda", current, parametros + [current.b], AType(Solver s) {
    return tipoFlecha([s.getType(p) | p <- parametros], s.getType(current.b));
  });
}

void collect(Instruccion current, Collector c) {
  if (current is instruccionExpresion) colectarInstruccionExpresion(current, c);
  else collect(hijos(current), c);
}

void collect(Objeto current, Collector c) {
  if (current is objeto) colectarObjeto(current, c);
  else if (current is tipoFuncion) colectarTipoFuncion(current, c);
  else collect(hijos(current), c);
}

void collect(Cuerpo current, Collector c) {
  if (current is cuerpoBloque) colectarCuerpoBloque(current, c);
  else if (current is cuerpoExpresion) colectarCuerpoExpresion(current, c);
  else collect(hijos(current), c);
}

void collect(Expresion current, Collector c) {
  if (current is entero) colectarEntero(current, c);
  else if (current is decimal) colectarDecimal(current, c);
  else if (current is booleano) colectarBooleano(current, c);
  else if (current is cadena) colectarCadena(current, c);
  else if (current is caracter) colectarCaracter(current, c);
  else if (current is ruta) colectarRuta(current, c);
  else if (current is instanciacion) colectarInstanciacion(current, c);
  else if (current is parentesis) colectarParentesis(current, c);
  else if (current is negacion) colectarNegacion(current, c);
  else if (etiqueta(current) in operadoresAritmeticos) colectarOperadoresAritmeticos(current, c);
  else if (etiqueta(current) in operadoresOrden) colectarOperadoresOrden(current, c);
  else if (etiqueta(current) in operadoresIgualdad) colectarOperadoresIgualdad(current, c);
  else if (etiqueta(current) in operadoresLogicos) colectarOperadoresLogicos(current, c);
  else if (current is condicional || current is condicionalBloque) colectarCondicional(current, c);
  else if (current is lambda) colectarLambda(current, c);
  else if (current is lambdaBloque) colectarLambdaBloque(current, c);
  else collect(hijos(current), c);
}
