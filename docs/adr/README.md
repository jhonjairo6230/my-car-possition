# Registro de decisiones de arquitectura (ADR)

Un **ADR** (*Architecture Decision Record*) es una nota corta que explica una
decisión importante: qué problema había, qué se eligió, qué se descartó y qué
consecuencias tiene.

Este proyecto sigue la misma forma de trabajar que
[DrawPad](https://github.com/jhonjairo6230/DrawPad): los ADR de DrawPad que
aplican se han **adoptado** aquí con su propio número.

| N.º | Decisión | Origen | Estado |
| --- | -------- | ------ | ------ |
| [0001](0001-registrar-decisiones-con-adr.md) | Registrar las decisiones con ADR | DrawPad 0001 | Aceptada |
| [0002](0002-git-flow.md) | Usar Git Flow como flujo de ramas | DrawPad 0002 | Aceptada |
| [0003](0003-clean-architecture-mvvm.md) | Clean Architecture con MVVM | DrawPad 0003 | Aceptada |
| [0004](0004-compilar-sin-mac.md) | Compilar sin Mac: GitHub Actions, XcodeGen e IPA sin firmar | DrawPad 0004 | Aceptada |
| [0005](0005-documentacion.md) | Documentar con Markdown + Mermaid y comentarios DocC | DrawPad 0006 | Aceptada |
| [0006](0006-swiftdata.md) | SwiftData como base de datos local | DrawPad 0007 | Aceptada |
| [0007](0007-guia-ar-del-asiento.md) | Guiar el asiento con realidad aumentada (cámara trasera), tomando el umbral como referencia | Propio | Aceptada |
| [0008](0008-camara-frontal-complemento.md) | Comprobar con la cara (cámara frontal) como complemento | Propio | Aceptada |
| [0009](0009-comparacion-en-vivo.md) | Comparar con mediana, tolerancias fijas y veredicto en vivo | Propio | Aceptada |
| [0010](0010-ci-solo-en-develop.md) | El workflow solo corre al fusionar en develop (o a mano) | Propio | Aceptada |

ADR de DrawPad que **no** aplican (son del lienzo de dibujo): 0005 PencilKit,
0008 papel y tema, 0009 zoom, 0010 cuadernos y 0011 suavizar trazos.

## Cómo añadir un ADR

1. Copia [`0000-plantilla.md`](0000-plantilla.md) con el siguiente número y un
   nombre corto.
2. Rellénalo y añádelo a la tabla de arriba.
3. Un ADR aceptado **no se reescribe**. Si la decisión cambia, se crea uno
   nuevo y el anterior pasa a estado *Reemplazada por 00NN*.
