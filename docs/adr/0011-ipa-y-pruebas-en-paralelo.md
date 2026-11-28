# 0011. IPA y pruebas en paralelo; el `.ipa` solo al fusionar

- **Estado:** Aceptada
- **Fecha:** 2026-11-28
- **Origen:** adoptado de [DrawPad ADR 0014](https://github.com/jhonjairo6230/DrawPad/blob/develop/docs/adr/0014-ipa-y-pruebas-en-paralelo.md)
  y [DrawPad ADR 0023](https://github.com/jhonjairo6230/DrawPad/blob/develop/docs/adr/0023-ipa-solo-al-fusionar.md)
- **Reemplaza:** [ADR 0010](0010-ci-solo-en-develop.md) y el punto del
  [ADR 0004](0004-compilar-sin-mac.md) que decía que las pruebas se ejecutan
  antes de generar el `.ipa`.

## Contexto

El workflow hacía todo en serie: primero las pruebas y, solo si pasaban, el
`.ipa`. Para instalar había que esperar a las pruebas de interfaz, y la
comprobación que más vale en este proyecto es **probar en el auto**: la
realidad aumentada, las cámaras y las medidas reales no existen en el
simulador.

Con el [ADR 0010](0010-ci-solo-en-develop.md) se pasó a correr solo al
fusionar en `develop`, para no llenar Actions de ejecuciones. Pero así un
pull request no tenía ningún check antes de fusionar. DrawPad ya había
resuelto lo mismo con sus ADR 0014 y 0023.

## Decisión

Igual que DrawPad, el workflow tiene **dos trabajos que corren a la vez**,
cada uno en su propio Mac:

1. **IPA:** genera el proyecto, compila y publica `CarPosition-unsigned.ipa`
   (unos 3 minutos). Solo corre en un **push a `develop` o `main`** (es
   decir, al fusionar un pull request) o **a mano** (Actions → Compilar IPA →
   Run workflow) sobre cualquier rama.
2. **Pruebas:** pruebas unitarias y de interfaz en un simulador de iPhone. Corre
   en **cada push** a las ramas de Git Flow y en **cada pull request**: es lo
   que dice si una rama se puede fusionar.

El `.ipa` no espera a las pruebas.

## Alternativas consideradas

- **Solo al fusionar** ([ADR 0010](0010-ci-solo-en-develop.md)): menos
  ejecuciones, pero sin check antes de fusionar.
- **Todo en serie:** el `.ipa` solo existiría con pruebas en verde, a costa de
  esperar a las pruebas para poder instalar.
- **Un `.ipa` en cada rama:** más ejecuciones y más cola en los Mac de GitHub,
  y casi ninguno se instala.

## Consecuencias

- Hay `.ipa` unos 3 minutos después de fusionar; probar en el auto no espera
  a las pruebas.
- Que exista un `.ipa` solo significa que la app **compila**. Si las pruebas
  pasaron lo dice el trabajo **Pruebas**.
- Un pull request no trae `.ipa`: el trabajo IPA aparece como omitido. Para
  probar una rama en el auto antes de fusionarla, se usa Run workflow.
- Cada ejecución en `develop` o `main` usa dos Mac a la vez (gratis al ser
  el repo público) y compila la app dos veces.
