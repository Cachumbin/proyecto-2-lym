module AST

data AstPrograma = programa(list[AstInstruccion] instrucciones);

data AstInstruccion
  = objetoCreador(str nombre, list[AstParametroDefinicion] genericos, list[AstParametroConstructor] campos, list[AstObjeto] extiende)
  | valDeclaracion(str nombre, list[AstObjeto] tipo, list[AstExpresion] valor)
  | varDeclaracion(str nombre, list[AstObjeto] tipo, list[AstExpresion] valor)
  | variableAsignacion(AstRuta destino, AstExpresion nuevoValor)
  | metodoPrincipal(AstBloque bloquePrincipal)
  | metodoExterno(str nombre, list[str] ruta, list[AstParametroMetodo] parametros, list[AstObjeto] tipo, list[AstBloque] cuerpo)
  | metodoOverride(str nombre, list[AstParametroMetodo] parametros, list[AstObjeto] tipo, AstBloque bloqueOverride)
  | ciclo(AstPatron patron, AstOperador operador, AstExpresion coleccion, AstCuerpo cuerpoCiclo)
  | instruccionExpresion(AstExpresion e)
  ;

data AstObjeto
  = objeto(str nombre, list[AstObjeto] argumentos)
  | tipoFuncion(list[AstObjeto] parametros, AstObjeto resultado)
  ;

data AstParametroDefinicion
  = covariante(str nombre)
  | contravariante(str nombre)
  | invariante(str nombre)
  ;

data AstParametroConstructor
  = parametroVal(str nombre, AstObjeto tipo)
  | parametroVar(str nombre, AstObjeto tipo)
  ;

data AstParametroMetodo = parametroMetodo(str nombre, AstObjeto tipo);

data AstBloque = bloque(list[AstInstruccion] instrucciones);

data AstPatron
  = patronVariable(str nombre)
  | patronTupla(list[str] nombres)
  ;

data AstOperador
  = desde()
  | en()
  ;

data AstCuerpo
  = cuerpoBloque(AstBloque b)
  | cuerpoExpresion(AstExpresion e)
  ;

data AstRuta
  = variable(str id)
  | acceso(AstRuta base, str campo)
  | llamada(AstRuta base, list[AstExpresion] argumentos)
  ;

data AstInstanciacion
  = instanciacionConArgumentos(AstObjeto ob, list[AstExpresion] argumentos, list[AstBloque] cuerpo)
  | instanciacionSimple(AstObjeto ob, list[AstBloque] cuerpo)
  ;

data AstCadena = cadenaLiteral(list[AstParteCadena] partes);

data AstCaracter = caracterLiteral(str valor);

data AstParteCadena
  = parteTexto(str t)
  | parteVariable(str nombre)
  | parteExpresion(AstExpresion e)
  ;

data AstExpresion
  = entero(int n)
  | decimal(real d)
  | booleano(bool b)
  | cadena(AstCadena c)
  | caracter(AstCaracter letra)
  | parentesis(AstExpresion e)
  | ruta(AstRuta r)
  | instanciacion(AstInstanciacion i)
  | negacion(AstExpresion e)
  | multiplicacion(AstExpresion izq, AstExpresion der)
  | division(AstExpresion izq, AstExpresion der)
  | modulo(AstExpresion izq, AstExpresion der)
  | potencia(AstExpresion izq, AstExpresion der)
  | suma(AstExpresion izq, AstExpresion der)
  | resta(AstExpresion izq, AstExpresion der)
  | menor(AstExpresion izq, AstExpresion der)
  | mayor(AstExpresion izq, AstExpresion der)
  | menorIgual(AstExpresion izq, AstExpresion der)
  | mayorIgual(AstExpresion izq, AstExpresion der)
  | distinto(AstExpresion izq, AstExpresion der)
  | igual(AstExpresion izq, AstExpresion der)
  | conjuncion(AstExpresion izq, AstExpresion der)
  | disyuncion(AstExpresion izq, AstExpresion der)
  | condicional(AstExpresion condicion, AstCuerpo entonces, AstExpresion sino)
  | condicionalBloque(AstExpresion condicion, AstCuerpo entonces, AstBloque bloqueSino)
  | lambda(list[AstParametroMetodo] parametros, AstExpresion cuerpo)
  | lambdaBloque(list[AstParametroMetodo] parametros, AstBloque bloqueLambda)
  ;