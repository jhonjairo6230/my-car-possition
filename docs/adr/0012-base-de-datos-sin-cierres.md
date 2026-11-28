# 0012. Si la base de datos no abre, la app no se cierra

- **Estado:** Aceptada
- **Fecha:** 2026-11-28
- **Cambia:** la consecuencia "si la base de datos no abre, `fatalError`" del
  [ADR 0006](0006-swiftdata.md).

## Contexto

La segunda versión de la app (guía del asiento) añadió a `ProfileRecord`
columnas **obligatorias** (`cushionX`…), saltándose la regla del
[ADR 0006](0006-swiftdata.md). En un iPhone que tenía la primera versión
instalada, SwiftData no podía migrar la base de datos, el `AppContainer`
llegaba al `fatalError` y la app **se abría y se cerraba** sin decir nada.
Las pruebas no lo vieron porque usan una base de datos en memoria, y con una
app instalada con Sideloadly no siempre aparece un informe del cierre.

## Decisión

1. Las columnas del asiento pasan a ser **opcionales**. Una fila sin asiento
   (de la primera versión) se ignora al leer.
2. Al arrancar, `SwiftDataProfileRepository.openRecovering()`:
   1. abre la base de datos del disco;
   2. si falla, **aparta** sus archivos (`default.store.apartado-<fecha>`, no
      los borra) y crea una vacía; la lista muestra un aviso con el error;
   3. si ni así, el `AppContainer` usa una base de datos **en memoria** y avisa
      de que lo que se guarde no se conservará.
3. Hay pruebas con la base de datos **en disco**: guardar y leer, abrir una
   base de datos con el esquema de la primera versión y recuperarse de un
   archivo que no es una base de datos.
4. Las cámaras (ARKit) se crean al abrir su primera pantalla, no al arrancar.

## Alternativas consideradas

- **Seguir con `fatalError`:** es lo que hace DrawPad, pero aquí dejó la app
  inservible y sin ningún mensaje para saber por qué.
- **Borrar la base de datos si no abre:** se perderían posiciones que quizá se
  podrían recuperar a mano.
- **`SchemaMigrationPlan` con versiones del esquema:** es lo correcto para
  cambios de verdad (renombrar, cambiar tipos), pero aquí bastaba con columnas
  opcionales; queda para cuando haga falta.

## Consecuencias

- La app siempre abre. En el peor caso, con una lista vacía y un aviso que
  dice qué falló.
- Las posiciones de la primera versión no se pueden usar: no tenían asiento.
- La regla de `AGENTS.md` sigue igual y ahora tiene una prueba que la vigila:
  toda propiedad nueva de un `@Model`, **opcional** o con valor por defecto.
