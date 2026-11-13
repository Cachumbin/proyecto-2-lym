module PruebasTipos

import List;
import Message;
import String;
import TypeChecker;

loc carpeta = |project://proyecto-2-lym/examples/tipado|;

list[loc] archivos(str subcarpeta) = [f | loc f <- (carpeta + subcarpeta).ls, f.extension == "ol"];

list[str] mensajes(loc archivo) = [m.msg | m <- erroresDeArchivo(archivo)];

bool reporta(str archivo, str nombre) {
  list[str] errores = mensajes(carpeta + "invalidos" + "<archivo>.ol");
  return any(e <- errores, contains(e, nombre));
}

test bool validosNoTienenErrores() = all(loc f <- archivos("validos"), isEmpty(mensajes(f)));

test bool invalidosTienenErrores() = all(loc f <- archivos("invalidos"), !isEmpty(mensajes(f)));

test bool padreInexistente() = reporta("padre_inexistente", "Fantasma");

test bool tipoDeCampoInexistente() = reporta("campo_tipo_inexistente", "Fantasma");

test bool parametroDeTipoInexistente() = reporta("parametro_tipo_inexistente", "U");

test bool padreGenericoInexistente() = reporta("padre_generico_inexistente", "Fantasma");

test bool argumentoDeTipoInexistente() = reporta("argumento_tipo_inexistente", "Fantasma");

test bool instanciaInexistente() = reporta("instancia_inexistente", "Fantasma");

test bool metodoDeObjetoInexistente() = reporta("metodo_de_objeto_inexistente", "Fantasma");

test bool overrideInexistente() = reporta("override_inexistente", "ladrar");

test bool campoInexistente() = reporta("campo_inexistente", "edad");

test bool metodoInexistente() = reporta("metodo_inexistente", "maullar");

test bool variableInexistente() = reporta("variable_inexistente", "variableInexistente");

test bool objetoDuplicado() = any(e <- mensajes(carpeta + "invalidos" + "objeto_duplicado.ol"), contains(e, "Double declaration"));

test bool asignacionConTipoIncorrecto() = reporta("tipo_asignacion", "`Int`") && reporta("tipo_asignacion", "`String`");

test bool caracterNoEsCadena() = reporta("tipo_caracter_cadena", "`Char`");

test bool operadorConTiposIncorrectos() = reporta("tipo_operador", "no está definido para `Int` y `Boolean`");

test bool negacionDeCadena() = reporta("tipo_negacion", "neg no está definido");

test bool ramasIncompatibles() = reporta("tipo_ramas", "incompatibles");

test bool operadorLogicoRequiereBoolean() = reporta("tipo_logico", "requiere Boolean");

test bool subtipoIncorrecto() = reporta("tipo_subtipo", "`Dog`");

test bool argumentoDeConstructor() = reporta("tipo_argumento_constructor", "el constructor espera `Int`");

test bool aridadDeConstructor() = reporta("tipo_aridad_constructor", "espera 2 argumentos pero recibió 1");

test bool argumentoDeMetodo() = reporta("tipo_argumento_metodo", "el parámetro espera `Int`");

test bool retornoDeMetodo() = reporta("tipo_retorno_metodo", "se declaró `Int`");

test bool invarianza() = reporta("tipo_invarianza", "`Caja[Animal]`");

test bool covarianzaInvalida() = reporta("tipo_covarianza_invalida", "`Lista[Dog]`");

test bool covarianteEnCampoVar() = reporta("tipo_varianza_campo", "covariante");

test bool covarianteEnParametroDeMetodo() = reporta("tipo_varianza_metodo", "parámetro de método");

test bool reasignarVal() = !isEmpty(mensajes(carpeta + "invalidos" + "tipo_reasignar_val.ol"));

test bool asignacionDeVariable() = reporta("tipo_asignacion_variable", "No se puede asignar");

test bool tipoDeLambda() = reporta("tipo_lambda", "`String`");

test bool llamarNoFuncion() = reporta("tipo_llamada_no_funcion", "No se puede llamar");
