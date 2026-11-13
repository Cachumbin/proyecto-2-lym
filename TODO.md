# TODO — Objectilang, Proyecto 3

## FASE 1 — Diagnóstico y entorno
- [x] Resumir estado del P2 (qué funciona, qué falla) y correr `checkExamples()` / `checkAst()`
- [x] Decidir extensión `.ol` (renombrar ejemplos y actualizar `Plugin.rsc`)
- [x] Declarar TypePal en `META-INF/RASCAL.MF` y verificar que importa
- [x] Crear `CAMBIOS.md` (bitácora)

## FASE 2 — Correcciones del P1/P2
- [x] Cadenas: `AsParteCadena` como producciones `syntax` con constructores 1 a 1 con el AST
- [x] Eliminar `partesCadena` y el parseo manual de strings en `Implode.rsc`
- [x] Interpolación como `syntax` (`${ x }` con espacios deriva), texto de la cadena `lexical`
- [x] `bracket`: constructor `parentesis` en AST y prueba `(1 + 2) * 3`
- [x] Operador `->` (tipos función) con precedencia, AST y `.ol` de ejemplo
- [x] Operador `=>` (lambda) con precedencia, AST y `.ol` de ejemplo
- [x] Revisar opcionales `list[...]` en el AST
- [x] Un `.ol` de prueba por cada corrección

## FASE 3 — Parser e implode
- [x] Parser y implode sobre todos los `.ol`
- [x] Pruebas de parseo válidas e inválidas

## FASE 4 — Anotaciones de tipo
- [x] Anotaciones para Int, Boolean, Char, String en la gramática
- [x] Tipo genérico dado por el usuario en objetos y estructuras de datos
- [x] Reflejar anotaciones en el AST

## FASE 5 — TypePal
- [x] `data AType` y `collect` por cada nodo
- [x] Tipos de Int/Bool/Char/String y operadores
- [x] Objetos, genéricos y varianza (`covariante`/`contravariante`)
- [x] Mensajes de error con tipo esperado y encontrado

## FASE 6 — Regla de existencia
- [x] Elementos usados en una definición de objeto deben existir
- [x] `.ol` válido y `.ol` inválido para la regla

## FASE 7 — Intérprete / generación
- [x] Ejecutar un `.ol` e imprimir solo el resultado en consola
- [x] `Main.rsc` con punto de entrada

## FASE 8 — Pruebas
- [x] Casos válidos (parsean, tipan, ejecutan)
- [x] Casos inválidos (error de tipo, elemento inexistente)

## FASE 9 — Entrega
- [ ] `CAMBIOS.md` completo
- [ ] Documento y `.zip` (solo cuando el usuario lo pida)
