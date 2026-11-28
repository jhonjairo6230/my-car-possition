# Mi Posición (my-car-possition)

App de iPhone con **ARKit** para recuperar tu posición de manejo cuando
alguien más usó el auto.

1. **Calibras una vez:** te sientas como te gusta manejar, pones el móvil en
   su soporte y pulsas **Calibrar**. La app guarda dónde está tu cabeza
   respecto al móvil.
2. **Cada vez que te devuelven el auto:** pones el móvil en el mismo soporte,
   abres tu posición y la app te dice en vivo qué tocar: *"Adelanta el asiento
   unos 3 cm"*, *"Sube el asiento unos 2 cm"*… hasta que sale **Todo en su
   sitio**.
3. Lo que la cámara no puede medir (espejos, volante) va en **notas** que se
   muestran al comprobar.

Necesita un iPhone con seguimiento facial (XS/XR o posterior). Se compila
sin Mac, en GitHub Actions, y se instala con Sideloadly, igual que
[DrawPad](https://github.com/jhonjairo6230/DrawPad).

## Documentación

| Documento | Qué cuenta |
| --------- | ---------- |
| [Uso en el auto](docs/uso-en-el-auto.md) | Cómo calibrar y comprobar, y consejos para que mida bien. |
| [Cómo funciona la medición](docs/como-funciona-la-medicion.md) | La geometría: de ARKit a "adelanta el asiento". |
| [Arquitectura](docs/arquitectura.md) | Capas, clases y secuencias. |
| [Compilación e instalación](docs/compilacion-e-instalacion.md) | Del push al iPhone sin Mac. |
| [Flujo de trabajo](docs/flujo-de-trabajo.md) | Git Flow. |
| [Decisiones (ADR)](docs/adr/README.md) | Por qué es así; incluye los ADR adoptados de DrawPad. |
