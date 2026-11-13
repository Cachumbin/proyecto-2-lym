module Interprete

import IO;
import List;
import Map;
import Set;
import String;
import util::Math;
import Implode;
import AST;

data Valor
  = vEntero(int n)
  | vDecimal(real d)
  | vBooleano(bool b)
  | vCadena(str s)
  | vCaracter(str c)
  | vUnidad()
  | vClase(str nombre)
  | vInstancia(int id)
  | vFuncion(list[AstParametroMetodo] parametros, CuerpoFuncion cuerpo, int ambito, int esto)
  ;

data CuerpoFuncion
  = cuerpoDeExpresion(AstExpresion e)
  | cuerpoDeBloque(AstBloque b)
  ;

data Ambito = ambito(int padre, int esto, map[str, Valor] variables);

data ObjetoVivo = objetoEnMemoria(str nombre, map[str, Valor] campos, map[str, Valor] metodos);

data ErrorEjecucion = errorEjecucion(str mensaje);

private map[int, Ambito] ambitos = ();
private map[int, ObjetoVivo] memoria = ();
private map[str, AstInstruccion] definiciones = ();
private map[str, map[str, AstInstruccion]] metodosExternos = ();
private int siguiente = 0;
private list[str] salida = [];
private bool eco = false;

private int nuevoId() {
  siguiente += 1;
  return siguiente;
}

private void reiniciar(bool imprimir) {
  ambitos = (0: ambito(-1, -1, ()));
  memoria = ();
  definiciones = ();
  metodosExternos = ();
  siguiente = 0;
  salida = [];
  eco = imprimir;
}

private void emitir(str texto) {
  salida += [texto];
  if (eco) print(texto);
}

private int nuevoAmbito(int padre, int esto) {
  int id = nuevoId();
  ambitos[id] = ambito(padre, esto, ());
  return id;
}

private void declarar(int donde, str nombre, Valor valor) {
  ambitos[donde].variables[nombre] = valor;
}

private bool existe(int donde, str nombre) {
  int actual = donde;
  while (actual >= 0) {
    Ambito a = ambitos[actual];
    if (nombre in a.variables) return true;
    if (a.esto >= 0 && nombre in memoria[a.esto].campos) return true;
    actual = a.padre;
  }
  return false;
}

private Valor buscar(int donde, str nombre) {
  int actual = donde;
  while (actual >= 0) {
    Ambito a = ambitos[actual];
    if (nombre in a.variables) return a.variables[nombre];
    if (a.esto >= 0 && nombre in memoria[a.esto].campos) return memoria[a.esto].campos[nombre];
    actual = a.padre;
  }
  throw errorEjecucion("Variable no definida: <nombre>");
}

private void asignar(int donde, str nombre, Valor valor) {
  int actual = donde;
  while (actual >= 0) {
    Ambito a = ambitos[actual];
    if (nombre in a.variables) {
      ambitos[actual].variables[nombre] = valor;
      return;
    }
    if (a.esto >= 0 && nombre in memoria[a.esto].campos) {
      memoria[a.esto].campos[nombre] = valor;
      return;
    }
    actual = a.padre;
  }
  throw errorEjecucion("Variable no definida: <nombre>");
}

private str textoReal(real d) {
  str t = "<d>";
  return endsWith(t, ".") ? "<t>0" : t;
}

private str texto(Valor v) {
  switch (v) {
    case vEntero(n): return "<n>";
    case vDecimal(d): return textoReal(d);
    case vBooleano(b): return b ? "true" : "false";
    case vCadena(s): return s;
    case vCaracter(c): return c;
    case vUnidad(): return "()";
    case vClase(nombre): return "class <nombre>";
    case vFuncion(_, _, _, _): return "\<function\>";
    case vInstancia(id): {
      ObjetoVivo vivo = memoria[id];
      list[str] campos = [texto(vivo.campos[k]) | k <- sort(domain(vivo.campos))];
      return isEmpty(campos) ? vivo.nombre : "<vivo.nombre>(<intercalate(", ", campos)>)";
    }
  }
  throw errorEjecucion("Valor sin representación");
}

private bool esNumero(Valor v) = v is vEntero || v is vDecimal;

private real comoReal(vEntero(n)) = n * 1.0;
private real comoReal(vDecimal(d)) = d;

private bool iguales(Valor a, Valor b) = esNumero(a) && esNumero(b) ? comoReal(a) == comoReal(b) : a == b;

private int comparar(Valor a, Valor b) {
  if (esNumero(a) && esNumero(b)) {
    real x = comoReal(a);
    real y = comoReal(b);
    return x < y ? -1 : (x > y ? 1 : 0);
  }
  if (vCadena(x) := a && vCadena(y) := b) return x < y ? -1 : (x > y ? 1 : 0);
  if (vCaracter(x) := a && vCaracter(y) := b) return x < y ? -1 : (x > y ? 1 : 0);
  throw errorEjecucion("No se pueden comparar <texto(a)> y <texto(b)>");
}

private Valor aritmetica(str operador, Valor a, Valor b) {
  if (operador == "+" && (a is vCadena || b is vCadena)) return vCadena(texto(a) + texto(b));
  if (!esNumero(a) || !esNumero(b)) {
    throw errorEjecucion("El operador <operador> no aplica a <texto(a)> y <texto(b)>");
  }
  if (vEntero(x) := a && vEntero(y) := b) {
    switch (operador) {
      case "+": return vEntero(x + y);
      case "-": return vEntero(x - y);
      case "*": return vEntero(x * y);
      case "/": {
        if (y == 0) throw errorEjecucion("División por cero");
        return vEntero(x / y);
      }
      case "%": {
        if (y == 0) throw errorEjecucion("División por cero");
        return vEntero(x % y);
      }
      case "**": return y >= 0 ? vEntero(potenciaEntera(x, y)) : vDecimal(1.0 / potenciaEntera(x, -y));
    }
  }
  real x = comoReal(a);
  real y = comoReal(b);
  switch (operador) {
    case "+": return vDecimal(x + y);
    case "-": return vDecimal(x - y);
    case "*": return vDecimal(x * y);
    case "/": {
      if (y == 0.0) throw errorEjecucion("División por cero");
      return vDecimal(x / y);
    }
    case "%": return vDecimal(x - y * floor(x / y));
    case "**": return vDecimal(exp(y * ln(x)));
  }
  throw errorEjecucion("Operador desconocido <operador>");
}

private int potenciaEntera(int base, int exponente) {
  int resultado = 1;
  for (_ <- [0..exponente]) resultado *= base;
  return resultado;
}

private bool booleano(Valor v) {
  if (vBooleano(b) := v) return b;
  throw errorEjecucion("Se esperaba un Boolean pero se obtuvo <texto(v)>");
}

private Valor evaluar(AstExpresion e, int donde) {
  switch (e) {
    case entero(n): return vEntero(n);
    case decimal(d): return vDecimal(d);
    case booleano(b): return vBooleano(b);
    case cadena(cadenaLiteral(partes)): return vCadena(("" | it + textoDeParte(p, donde) | p <- partes));
    case caracter(caracterLiteral(valor)): return vCaracter(valor);
    case parentesis(interno): return evaluar(interno, donde);
    case ruta(r): return evaluarRuta(r, donde);
    case instanciacion(i): return instanciar(i, donde);
    case negacion(interno): return negar(evaluar(interno, donde));
    case multiplicacion(izq, der): return aritmetica("*", evaluar(izq, donde), evaluar(der, donde));
    case division(izq, der): return aritmetica("/", evaluar(izq, donde), evaluar(der, donde));
    case modulo(izq, der): return aritmetica("%", evaluar(izq, donde), evaluar(der, donde));
    case potencia(izq, der): return aritmetica("**", evaluar(izq, donde), evaluar(der, donde));
    case suma(izq, der): return aritmetica("+", evaluar(izq, donde), evaluar(der, donde));
    case resta(izq, der): return aritmetica("-", evaluar(izq, donde), evaluar(der, donde));
    case menor(izq, der): return vBooleano(comparar(evaluar(izq, donde), evaluar(der, donde)) < 0);
    case mayor(izq, der): return vBooleano(comparar(evaluar(izq, donde), evaluar(der, donde)) > 0);
    case menorIgual(izq, der): return vBooleano(comparar(evaluar(izq, donde), evaluar(der, donde)) <= 0);
    case mayorIgual(izq, der): return vBooleano(comparar(evaluar(izq, donde), evaluar(der, donde)) >= 0);
    case igual(izq, der): return vBooleano(iguales(evaluar(izq, donde), evaluar(der, donde)));
    case distinto(izq, der): return vBooleano(!iguales(evaluar(izq, donde), evaluar(der, donde)));
    case conjuncion(izq, der): return vBooleano(booleano(evaluar(izq, donde)) && booleano(evaluar(der, donde)));
    case disyuncion(izq, der): return vBooleano(booleano(evaluar(izq, donde)) || booleano(evaluar(der, donde)));
    case condicional(condicion, entonces, sino):
      return booleano(evaluar(condicion, donde)) ? evaluarCuerpo(entonces, donde) : evaluar(sino, donde);
    case condicionalBloque(condicion, entonces, bloqueSino):
      return booleano(evaluar(condicion, donde)) ? evaluarCuerpo(entonces, donde) : evaluarBloque(bloqueSino, donde);
    case lambda(parametros, cuerpo): return vFuncion(parametros, cuerpoDeExpresion(cuerpo), donde, -1);
    case lambdaBloque(parametros, bloqueLambda): return vFuncion(parametros, cuerpoDeBloque(bloqueLambda), donde, -1);
  }
  throw errorEjecucion("Expresión no soportada");
}

private Valor negar(Valor v) {
  if (vBooleano(b) := v) return vBooleano(!b);
  if (vEntero(n) := v) return vEntero(-n);
  if (vDecimal(d) := v) return vDecimal(-d);
  throw errorEjecucion("neg no está definido para <texto(v)>");
}

private str textoDeParte(AstParteCadena parte, int donde) {
  switch (parte) {
    case parteTexto(t): return t;
    case parteVariable(nombre): return texto(buscar(donde, nombre));
    case parteExpresion(e): return texto(evaluar(e, donde));
  }
  return "";
}

private Valor evaluarCuerpo(AstCuerpo cuerpo, int donde) {
  switch (cuerpo) {
    case cuerpoBloque(b): return evaluarBloque(b, donde);
    case cuerpoExpresion(e): return evaluar(e, donde);
  }
  return vUnidad();
}

private Valor evaluarBloque(AstBloque b, int donde) = ejecutarSecuencia(b.instrucciones, nuevoAmbito(donde, ambitos[donde].esto));

private Valor ejecutarSecuencia(list[AstInstruccion] instrucciones, int donde) {
  Valor ultimo = vUnidad();
  for (i <- instrucciones) ultimo = ejecutar(i, donde);
  return ultimo;
}

private list[Valor] evaluarTodos(list[AstExpresion] expresiones, int donde) = [evaluar(e, donde) | e <- expresiones];

private Valor evaluarRuta(AstRuta r, int donde) {
  switch (r) {
    case variable(id): return buscar(donde, id);
    case acceso(base, campo): return acceder(evaluarRuta(base, donde), campo);
    case llamada(base, argumentos): return llamar(base, evaluarTodos(argumentos, donde), donde);
  }
  throw errorEjecucion("Ruta no soportada");
}

private Valor acceder(Valor base, str campo) {
  if (vInstancia(id) := base) {
    ObjetoVivo vivo = memoria[id];
    if (campo in vivo.campos) return vivo.campos[campo];
    if (campo == "getClass") return vClase(vivo.nombre);
    Valor metodo = buscarMetodo(id, campo);
    if (metodo is vFuncion) return invocar(metodo, []);
    throw errorEjecucion("<vivo.nombre> no tiene el miembro <campo>");
  }
  if (vClase(nombre) := base && campo == "getSimpleName") return vCadena(nombre);
  throw errorEjecucion("No se puede acceder a <campo> en <texto(base)>");
}

private Valor buscarMetodo(int id, str nombre) {
  ObjetoVivo vivo = memoria[id];
  if (nombre in vivo.metodos) return vivo.metodos[nombre];
  for (str tipo <- ascendencia(vivo.nombre)) {
    if (tipo in metodosExternos && nombre in metodosExternos[tipo]) {
      AstInstruccion m = metodosExternos[tipo][nombre];
      if (isEmpty(m.cuerpo)) throw errorEjecucion("El método <nombre> de <tipo> es abstracto");
      return vFuncion(m.parametros, cuerpoDeBloque(m.cuerpo[0]), 0, id);
    }
  }
  return vUnidad();
}

private list[str] ascendencia(str nombre) {
  list[str] resultado = [nombre];
  if (nombre in definiciones) {
    for (AstObjeto padre <- definiciones[nombre].extiende, padre is objeto) {
      resultado += ascendencia(padre.nombre);
    }
  }
  return resultado;
}

private Valor llamar(AstRuta base, list[Valor] argumentos, int donde) {
  if (variable("print") := base && !existe(donde, "print")) return imprimir(argumentos, false);
  if (variable("println") := base && !existe(donde, "println")) return imprimir(argumentos, true);
  if (acceso(objetivo, nombre) := base) {
    Valor receptor = evaluarRuta(objetivo, donde);
    if (vInstancia(id) := receptor) {
      ObjetoVivo vivo = memoria[id];
      if (nombre in vivo.campos) return invocar(vivo.campos[nombre], argumentos);
      Valor metodo = buscarMetodo(id, nombre);
      if (metodo is vFuncion) return invocar(metodo, argumentos);
      throw errorEjecucion("<vivo.nombre> no tiene el método <nombre>");
    }
    return invocar(acceder(receptor, nombre), argumentos);
  }
  return invocar(evaluarRuta(base, donde), argumentos);
}

private Valor imprimir(list[Valor] argumentos, bool salto) {
  str linea = intercalate(" ", [texto(a) | a <- argumentos]);
  emitir(salto ? "<linea>\n" : linea);
  return isEmpty(argumentos) ? vUnidad() : argumentos[0];
}

private Valor invocar(Valor funcion, list[Valor] argumentos) {
  if (vFuncion(parametros, cuerpo, capturado, esto) := funcion) {
    if (size(parametros) != size(argumentos)) {
      throw errorEjecucion("Se esperaban <size(parametros)> argumentos y llegaron <size(argumentos)>");
    }
    int local = nuevoAmbito(capturado, esto);
    for (i <- index(parametros)) declarar(local, parametros[i].nombre, argumentos[i]);
    switch (cuerpo) {
      case cuerpoDeExpresion(e): return evaluar(e, local);
      case cuerpoDeBloque(b): return ejecutarSecuencia(b.instrucciones, nuevoAmbito(local, esto));
    }
  }
  throw errorEjecucion("<texto(funcion)> no se puede invocar");
}

private Valor instanciar(AstInstanciacion i, int donde) {
  str nombre = i.ob.nombre;
  if (nombre notin definiciones) throw errorEjecucion("ObjetoVivo no definido: <nombre>");
  list[AstParametroConstructor] formales = definiciones[nombre].campos;
  list[Valor] argumentos = i is instanciacionConArgumentos ? evaluarTodos(i.argumentos, donde) : [];
  if (size(formales) != size(argumentos)) {
    throw errorEjecucion("<nombre> espera <size(formales)> argumentos y recibió <size(argumentos)>");
  }
  int id = nuevoId();
  map[str, Valor] campos = (formales[k].nombre: argumentos[k] | k <- index(formales));
  map[str, Valor] metodos = ();
  memoria[id] = objetoEnMemoria(nombre, campos, metodos);
  for (AstBloque b <- i.cuerpo, AstInstruccion m <- b.instrucciones, m is metodoOverride) {
    metodos[m.nombre] = vFuncion(m.parametros, cuerpoDeBloque(m.bloqueOverride), donde, id);
  }
  memoria[id].metodos = metodos;
  return vInstancia(id);
}

private Valor ejecutar(AstInstruccion i, int donde) {
  switch (i) {
    case objetoCreador(_, _, _, _): return vUnidad();
    case metodoExterno(_, _, _, _, _): return vUnidad();
    case metodoOverride(_, _, _, _): return vUnidad();
    case valDeclaracion(nombre, _, valor): {
      declarar(donde, nombre, isEmpty(valor) ? vUnidad() : evaluar(valor[0], donde));
      return vUnidad();
    }
    case varDeclaracion(nombre, _, valor): {
      declarar(donde, nombre, isEmpty(valor) ? vUnidad() : evaluar(valor[0], donde));
      return vUnidad();
    }
    case variableAsignacion(destino, nuevoValor): {
      asignarRuta(destino, evaluar(nuevoValor, donde), donde);
      return vUnidad();
    }
    case metodoPrincipal(bloquePrincipal): {
      evaluarBloque(bloquePrincipal, donde);
      return vUnidad();
    }
    case ciclo(patron, _, coleccion, cuerpoCiclo): {
      recorrer(patron, evaluar(coleccion, donde), cuerpoCiclo, donde);
      return vUnidad();
    }
    case instruccionExpresion(e): return evaluar(e, donde);
  }
  throw errorEjecucion("Instrucción no soportada");
}

private void asignarRuta(AstRuta destino, Valor valor, int donde) {
  switch (destino) {
    case variable(id): asignar(donde, id, valor);
    case acceso(base, campo): {
      if (vInstancia(id) := evaluarRuta(base, donde) && campo in memoria[id].campos) {
        memoria[id].campos[campo] = valor;
      } else {
        throw errorEjecucion("No se puede asignar a <campo>");
      }
    }
    default: throw errorEjecucion("Destino de asignación inválido");
  }
}

private list[Valor] elementos(Valor coleccion) {
  if (vInstancia(id) := coleccion) {
    ObjetoVivo vivo = memoria[id];
    return [vivo.campos[k] | k <- sort(domain(vivo.campos))];
  }
  throw errorEjecucion("No se puede iterar sobre <texto(coleccion)>");
}

private void recorrer(AstPatron patron, Valor coleccion, AstCuerpo cuerpo, int donde) {
  for (Valor elemento <- elementos(coleccion)) {
    int local = nuevoAmbito(donde, ambitos[donde].esto);
    switch (patron) {
      case patronVariable(nombre): declarar(local, nombre, elemento);
      case patronTupla(nombres): {
        list[Valor] partes = elementos(elemento);
        if (size(partes) < size(nombres)) throw errorEjecucion("El elemento no tiene <size(nombres)> componentes");
        for (k <- index(nombres)) declarar(local, nombres[k], partes[k]);
      }
    }
    evaluarCuerpo(cuerpo, local);
  }
}

private void registrar(AstPrograma programa) {
  for (i <- programa.instrucciones) {
    switch (i) {
      case objetoCreador(nombre, _, _, _): definiciones[nombre] = i;
      case metodoExterno(objetoDestino, ruta, _, _, _): {
        if (objetoDestino notin metodosExternos) metodosExternos[objetoDestino] = ();
        metodosExternos[objetoDestino][last(ruta)] = i;
      }
    }
  }
}

str ejecutarAst(AstPrograma programa, bool imprimirEnConsola) {
  reiniciar(imprimirEnConsola);
  registrar(programa);
  ejecutarSecuencia(programa.instrucciones, 0);
  if (imprimirEnConsola && !isEmpty(salida) && !endsWith(last(salida), "\n")) println();
  return ("" | it + s | s <- salida);
}

str ejecutarTexto(str texto) = ejecutarAst(desdeTexto(texto), false);

str ejecutarArchivo(loc archivo) = ejecutarAst(cargar(archivo), false);
