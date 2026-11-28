# 0010. El workflow solo corre al fusionar en develop (o a mano)

- **Estado:** Aceptada
- **Fecha:** 2026-11-28

## Contexto

El workflow **Compilar IPA** se heredó de DrawPad: corría en cada push a
cualquier rama de Git Flow y en cada pull request. Cada commit en una
`feature/` lanzaba unos 10 minutos de Mac en la nube, y un push seguido de
otro cancelaba el anterior a medias. Ver Actions lleno de ejecuciones de
commits sueltos no aporta: lo que interesa es el `.ipa` de lo que ya está
integrado.

## Decisión

El workflow corre solo:

1. **Al fusionar en `develop`** (`push` a `develop`: un merge de pull request
   lo es).
2. **A mano** (`workflow_dispatch`): Actions → Compilar IPA → Run workflow,
   eligiendo la rama. Sirve para probar una `feature/` antes de fusionarla.

No corre en pushes a `feature/`, `release/`, `hotfix/`, `backport/` ni
`main`, ni en pull requests.

## Alternativas consideradas

- **Dejarlo como en DrawPad** (cada push y cada PR): detecta errores antes de
  fusionar, pero llena Actions y gasta minutos en cada commit.
- **Solo en pull requests:** compila antes de fusionar, pero cada push a la
  rama del PR lo vuelve a lanzar.
- **Quitar también el lanzamiento a mano:** más estricto, pero sin forma de
  probar una rama en el iPhone antes de fusionarla.

## Consecuencias

- Actions solo muestra ejecuciones de `develop` y las lanzadas a mano.
- **Un error de compilación puede llegar a `develop`**: el pull request no
  tiene un check automático. Si hay dudas, lanzar el workflow a mano sobre la
  rama antes de fusionar.
- `main` no compila sola: el `.ipa` de una versión es el de `develop` justo
  antes de la release (o se lanza a mano sobre `main`).
- Se aparta de DrawPad en este punto; el resto del ADR 0004 sigue igual.
