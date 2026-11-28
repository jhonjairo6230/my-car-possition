# 0006. SwiftData como base de datos local

- **Estado:** Aceptada; el `fatalError` al no abrir, cambiado por [0012](0012-base-de-datos-sin-cierres.md)
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0007](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0007-swiftdata.md)

## Contexto

Hay que guardar una o varias **posiciones** (por ejemplo "Mi posición" y
"Viaje largo"), cada una con su medición de referencia y sus notas, y que
sigan ahí al cerrar la app. Todo en el propio iPhone, sin cuentas.

## Decisión

Igual que DrawPad, **SwiftData** con el modelo definido en código:

- `ProfileRecord` (`@Model`) guarda la medición "aplanada" en columnas
  `Double` (`depth`, `height`, `lateral`, `gravityX/Y/Z`).
- `SwiftDataProfileRepository` implementa `ProfileRepository` y es el único
  que conoce SwiftData. Traduce sus errores a `PositionError.storageFailed`.
- Las vistas no usan `@Query` ni `modelContext`: piden los datos a su
  ViewModel.
- Las pruebas de interfaz arrancan con `-uiTesting`: base de datos en memoria.

## Alternativas consideradas

- **`UserDefaults` con JSON:** sería suficiente para pocas posiciones, pero
  DrawPad ya enseña SwiftData y así los dos proyectos se mantienen igual.
- **Core Data:** necesita el editor de modelos de Xcode.
- **Guardar la medición como `Codable` en una columna:** menos código, pero
  opaco en la base de datos y más delicado de migrar.

## Consecuencias

- Las mismas que en DrawPad: toda propiedad nueva en un `@Model` debe ser
  **opcional** o tener valor por defecto; desinstalar la app borra las
  posiciones; si la base de datos no abre, `fatalError`.
- Hay código de mapeo entre `ProfileRecord` y `DrivingProfile`.
