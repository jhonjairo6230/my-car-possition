# 0001. Registrar las decisiones con ADR

- **Estado:** Aceptada
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0001](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0001-registrar-decisiones-con-adr.md)

## Contexto

Mi Posición es un proyecto personal, hermano de DrawPad: una app de iOS que
no se va a publicar pero a la que se quiere **volver para estudiarla**. Sin
un registro, el motivo de cada decisión (por qué ARKit, por qué medir desde
el móvil) se olvida.

## Decisión

Igual que en DrawPad: cada decisión de arquitectura o de proceso se escribe
como un ADR corto en `docs/adr/`, numerado y en español, con la
[plantilla](0000-plantilla.md).

Los ADR de DrawPad que también aplican aquí se **adoptan** como ADR propios
(con su número en este repo y un enlace al original). Los que son solo de
dibujo (PencilKit, papel, zoom, cuadernos, suavizado) no se copian.

## Alternativas consideradas

- **Enlazar a los ADR de DrawPad sin copiarlos:** menos texto, pero los
  detalles cambian (iPhone en lugar de iPad, ARKit en lugar de PencilKit) y
  un cambio en DrawPad cambiaría las reglas de este proyecto sin avisar.
- **Explicarlo todo en el README:** mezcla el "cómo se usa" con el "por qué".

## Consecuencias

- Cada decisión se lee en dos minutos, con sus alternativas.
- Los dos proyectos se parecen: lo aprendido en uno sirve en el otro.
- Los ADR no se editan: si algo cambia, se añade uno nuevo que reemplaza al
  anterior.
