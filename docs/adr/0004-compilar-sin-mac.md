# 0004. Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar

- **Estado:** Aceptada
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0004](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0004-compilar-sin-mac.md)

## Contexto

Igual que en DrawPad: no hay Mac ni cuenta de pago de Apple Developer, y la
app es solo para el iPhone propio.

## Decisión

Lo mismo que DrawPad:

1. **Compilar en GitHub Actions** (`macos-latest`).
2. **Generar el proyecto con XcodeGen** desde `project.yml`; ni el
   `.xcodeproj` ni el `Info.plist` van en git.
3. **Publicar un `.ipa` sin firmar** (`CarPosition-unsigned.ipa`) y
   **firmarlo e instalarlo con Sideloadly** con un Apple ID gratuito.
4. El workflow ejecuta las pruebas en un **simulador de iPhone** antes de
   generar el `.ipa` (`scripts/pick_iphone_simulator.py`).

Diferencias con DrawPad: el destino es **iPhone** (`TARGETED_DEVICE_FAMILY: 1`)
y hace falta el permiso de cámara (`NSCameraUsageDescription` en
`project.yml`).

Guía práctica: [compilacion-e-instalacion.md](../compilacion-e-instalacion.md).

## Alternativas consideradas

Las mismas que en DrawPad (guardar el `.xcodeproj`, Swift Playgrounds,
cuenta de pago, AltStore, Mac en la nube). Además:

- **Pruebas en un iPhone real desde el CI:** imposible sin dispositivo
  conectado; ARKit solo se comprueba a mano.

## Consecuencias

- Ni Mac ni pagos.
- Sin compilador local: un cambio se comprueba al fusionarlo en `develop` o
  lanzando el workflow a mano ([ADR 0010](0010-ci-solo-en-develop.md)).
- **ARKit no funciona en el simulador:** las pruebas de interfaz usan una
  cámara simulada (ver [ADR 0007](0007-guia-ar-del-asiento.md)) y la
  medición real solo se valida en el auto.
- La firma gratuita caduca a los 7 días y hay un límite de 3 apps por
  dispositivo (DrawPad ya ocupa una).
- Objetivo mínimo: **iOS 17** (por `@Observable` y SwiftData).
