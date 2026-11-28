# Mi Posición — notas del proyecto

App de iPhone (SwiftUI + ARKit) que guía con **realidad aumentada** (cámara
trasera) hasta la posición guardada del asiento, tomando el umbral de la
puerta como referencia; como complemento, comprueba con la cámara frontal
dónde queda la cabeza respecto al móvil en su soporte. Hermana de DrawPad: mismas reglas. Se compila solo
en GitHub Actions: **no hay Mac ni compilador de Swift en local**.
Documentación en `docs/`; decisiones en `docs/adr/`.

## Reglas de arquitectura

- `CarPosition/Domain` solo importa `Foundation`. Nada de `SwiftUI`, `UIKit`,
  `ARKit`, `simd` ni `SwiftData`. La geometría usa `Vector3`.
- `Presentation` no conoce `Data`: el ViewModel recibe casos de uso.
- ARKit solo se toca en `Presentation/Scanning/ARKitSeatScanner.swift`
  (cámara trasera) y `Presentation/Tracking/ARKitHeadTracker.swift` (frontal).
  Los ViewModel usan los protocolos `SeatScanner` y `HeadTracker`; las vistas,
  `CameraPreviewSource`. Lo que se dibuja en AR se describe con `AROverlay`
  (los ViewModel no conocen SceneKit).
- Hay **una** instancia de cada cámara. Cada pantalla la toma en `onAppear`
  y la suelta en `onDisappear`. Nunca se navega directamente de una pantalla
  con cámara a otra con cámara.
- El asiento se guarda en coordenadas del auto (`CarFrame`, a partir del
  umbral), nunca en coordenadas de ARKit, que cambian en cada sesión.
- Las implementaciones concretas solo se crean en `App/AppContainer.swift`,
  todo `lazy`. Con `-uiTesting`: base de datos en memoria,
  `SimulatedSeatScanner` y `SimulatedHeadTracker`.
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

El workflow **Compilar IPA** solo corre al fusionar en `develop` o a mano
(Actions → Compilar IPA → Run workflow, eligiendo la rama); ver
`docs/adr/0010-ci-solo-en-develop.md`. El workflow
(`.github/workflows/build.yml`) ejecuta las pruebas unitarias y de interfaz en un
simulador de iPhone y publica `CarPosition-unsigned.ipa`. ARKit no funciona en
el simulador: la realidad aumentada y las medidas reales se prueban en el auto.

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
