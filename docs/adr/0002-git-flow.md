# 0002. Usar Git Flow como flujo de ramas

- **Estado:** Aceptada
- **Fecha:** 2026-11-25
- **Origen:** adoptado de [DrawPad ADR 0002](https://github.com/jhonjairo6230/DrawPad/blob/main/docs/adr/0002-git-flow.md), con una excepción

## Contexto

Se quiere el mismo flujo de ramas que en DrawPad para no recordar reglas
distintas. Cada rama produce un `.ipa` instalable, así que conviene separar
"lo que estoy probando" de "la versión que funciona".

## Decisión

Se usa **Git Flow**, igual que en DrawPad:

- `main`: versiones publicadas. `develop`: integración.
- Ramas de trabajo `feature/`, `release/`, `backport/` y `hotfix/`, en
  minúsculas y con guiones.
- Nada de commits directos en `main` ni en `develop`: todo por pull request
  con el workflow en verde. De `develop` a `main` solo se pasa por `release/`.
- Versionado semántico en `project.yml` (`MARKETING_VERSION`).

**Excepción respecto a DrawPad:** las sesiones de Claude Code **en la nube**
solo pueden subir a ramas `claude/…`. Se aceptan solo como ramas de paso: su
contenido entra a `develop` por pull request (o se copia a una
`feature/…`), nunca directo a `main`. El workflow también compila esas
ramas para poder comprobarlas. Con un asistente en local se siguen usando
solo los prefijos de Git Flow.

Detalle en [flujo-de-trabajo.md](../flujo-de-trabajo.md).

## Alternativas consideradas

- **GitHub Flow** o **trunk-based:** más simples, pero distintos de DrawPad y
  sin separar pruebas de versión estable.
- **Prohibir `claude/…` como en DrawPad:** imposible desde la nube; habría
  que renombrar a mano cada rama antes de verla compilar.

## Consecuencias

- `main` siempre tiene una versión que funcionó en el iPhone.
- Una release necesita dos pull requests (release y backport).
- Hay un prefijo más que en DrawPad, limitado a las sesiones en la nube.
