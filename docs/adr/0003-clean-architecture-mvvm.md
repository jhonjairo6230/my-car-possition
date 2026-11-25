# 0003. Clean Architecture con MVVM

- **Estado:** Aceptada
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0003](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0003-clean-architecture-mvvm.md)

## Contexto

La parte delicada de la app no son las pantallas sino **las cuentas**: pasar
de lo que ve ARKit a "adelanta el asiento 3 cm". Esas cuentas tienen que
poder probarse sin iPhone, sin cámara y sin ARKit (el simulador del CI no
tiene ninguna de las tres cosas).

## Decisión

Las mismas cuatro capas que DrawPad, con dependencias solo hacia dentro:

- **Domain:** entidades (`PostureSample`, `PostureMeasurement`,
  `DrivingProfile`, `PositionEvaluation`), errores, servicios puros
  (`PostureGeometry`, `PositionEvaluator`), el puerto `ProfileRepository`
  y los casos de uso. Solo `Foundation`: ni ARKit ni `simd`.
- **Data:** `SwiftDataProfileRepository`.
- **Presentation:** SwiftUI con **MVVM** y `@Observable`. Los ViewModel
  hablan con la cámara a través del protocolo `HeadTracker` (el equivalente
  al `DrawingCanvas` de DrawPad).
- **App:** `AppContainer` como *composition root*, todo `lazy`.

Todo en un único target; las capas son carpetas.

## Alternativas consideradas

- **Todo en la vista:** la geometría quedaría mezclada con `ARSCNView` y sin
  pruebas.
- **Un paquete Swift por capa, TCA o VIPER:** descartados por las mismas
  razones que en DrawPad (complejidad o dependencias para una app pequeña).

## Consecuencias

- La geometría, la mediana, la evaluación y los ViewModel tienen pruebas
  unitarias con un rastreador falso (`FakeHeadTracker`).
- Cambiar ARKit por otro sensor afecta a un solo archivo.
- Más archivos de los que una app tan pequeña necesita: coste asumido por el
  valor didáctico.
- Nada impide saltarse las reglas: se respetan por disciplina (`AGENTS.md`).
