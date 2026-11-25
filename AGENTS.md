# Mi Posición — notas del proyecto

App de iPhone (SwiftUI + ARKit) que mide la posición de la cabeza del
conductor respecto al móvil fijo en su soporte y dice qué ajustar para volver
a una posición guardada. Hermana de DrawPad: mismas reglas. Se compila solo
en GitHub Actions: **no hay Mac ni compilador de Swift en local**.
Documentación en `docs/`; decisiones en `docs/adr/`.

## Reglas de arquitectura

- `CarPosition/Domain` solo importa `Foundation`. Nada de `SwiftUI`, `UIKit`,
  `ARKit`, `simd` ni `SwiftData`. La geometría usa `Vector3`.
- `Presentation` no conoce `Data`: el ViewModel recibe casos de uso.
- ARKit solo se toca en `Presentation/Tracking/ARKitHeadTracker.swift`. Los
  ViewModel usan el protocolo `HeadTracker`; las vistas, `CameraPreviewSource`.
- Hay **un solo** rastreador en toda la app (una sesión de ARKit). Cada
  pantalla lo toma en `onAppear` y lo suelta en `onDisappear`.
- Las implementaciones concretas solo se crean en `App/AppContainer.swift`,
  todo `lazy`. Con `-uiTesting`: base de datos en memoria y
  `SimulatedHeadTracker`.
- `Data` convierte sus errores a `PositionError`.
- `ProfileRecord` (`@Model`) no sale de `Data`. Toda propiedad nueva debe ser
  **opcional** o tener valor por defecto (ver `docs/adr/0006-swiftdata.md`).
- Distancias en **metros** en el dominio; centímetros solo en la interfaz.
- En la interfaz se dice **posición**; en el código, `DrivingProfile`.
- Cada tipo lleva un comentario `///` que explica su papel (el porqué).
- Interfaz, comentarios y documentación en español; identificadores en inglés.
- Lógica nueva → pruebas en `CarPositionTests` con los dobles de `Doubles/`.
- Pantallas o flujos nuevos → prueba en `CarPositionUITests`.

## Proyecto de Xcode

- La fuente de verdad es `project.yml` (XcodeGen). No se guardan en git ni el
  `.xcodeproj` ni `CarPosition/Resources/Info.plist`.
- Permisos (`NSCameraUsageDescription`…) van en `project.yml` → `info.properties`.

## Comprobar un cambio

Push a la rama y mirar el workflow **Compilar IPA**
(`.github/workflows/build.yml`): pruebas unitarias y de interfaz en un
simulador de iPhone y publica `CarPosition-unsigned.ipa`. ARKit no funciona en
el simulador: la medición real se prueba en el auto.

## Documentación

- Si cambia un flujo o una capa, actualiza `docs/arquitectura.md`.
- Si cambian las cuentas, actualiza `docs/como-funciona-la-medicion.md`.
- Una decisión importante → nuevo ADR en `docs/adr/` y su fila en
  `docs/adr/README.md`. Los ADR aceptados no se reescriben.

## Flujo de ramas (Git Flow)

| Rama | Sale de | PR hacia | Para qué |
| ---- | ------- | -------- | -------- |
| `feature/<nombre>` | `develop` | `develop` | Cualquier funcionalidad, arreglo o documentación. |
| `release/<x.y.z>` | `develop` | `main` | Preparar una versión: subir `MARKETING_VERSION`. |
| `backport/<x.y.z>` | `main` (tras la release) | `develop` | Igualar `develop` con `main`. |
| `hotfix/<x.y.z>` | `main` | `main` | Arreglo urgente. Después, `backport/<x.y.z>`. |

- **Nunca** un PR de `develop` a `main` ni commits directos en `develop` o `main`.
- **No uses ramas `claude/…`** ni otros prefijos.
- Versionado semántico: funcionalidad sube `y`, arreglos suben `z`.
