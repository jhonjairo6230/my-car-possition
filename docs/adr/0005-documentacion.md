# 0005. Documentar con Markdown + Mermaid y comentarios DocC

- **Estado:** Aceptada
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0006](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0006-documentacion.md)

## Contexto

La documentación tiene que leerse desde Windows y desde GitHub, sin Xcode, e
incluir diagramas.

## Decisión

Igual que DrawPad:

1. Comentarios `///` con sintaxis DocC en cada tipo, explicando el
   **porqué**.
2. Guías en `docs/` en Markdown con diagramas **Mermaid**:
   `arquitectura.md`, `como-funciona-la-medicion.md`,
   `compilacion-e-instalacion.md`, `uso-en-el-auto.md`,
   `flujo-de-trabajo.md` y `adr/`.
3. Documentación, comentarios e interfaz en **español**; identificadores en
   **inglés**.

## Alternativas consideradas

Las mismas que en DrawPad: catálogo DocC (necesita Xcode y no dibuja
Mermaid), DocC en GitHub Pages, diagramas como imágenes, wiki.

## Consecuencias

- Todo se lee en GitHub y los diagramas se revisan en el mismo pull request
  que el código.
- Los diagramas se actualizan a mano.
