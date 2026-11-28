# Mi Posición (my-car-possition)

App de iPhone con **realidad aumentada (ARKit)** para recuperar tu posición
de manejo cuando alguien más usó el auto.

1. **Guardas tu asiento una vez:** con la **cámara trasera** apuntas a la
   pisadera de la puerta (la parte de abajo del marco: la referencia fija del
   auto) y marcas tres puntos del
   asiento: el borde del cojín y dos del respaldo.
2. **Cuando te devuelven el auto:** marcas otra vez la pisadera y la app
   **dibuja sobre el asiento real el asiento ideal** (una bola y una barra
   verdes). Apuntas al cojín y al respaldo y te dice en vivo qué tocar:
   *"Adelanta el asiento unos 3 cm"*, *"Endereza el respaldo unos 4°"*, con el
   **arco del ángulo** dibujado, hasta que sale **en su sitio**.
3. **Complemento con la cámara frontal:** con el móvil en su soporte, la app
   comprueba que tu cabeza queda donde siempre.
4. Lo que no se mide (espejos, volante) va en **notas**.

Funciona en cualquier iPhone con ARKit; con LiDAR, la guía es más precisa.
Se compila sin Mac, en GitHub Actions, y se instala con Sideloadly, igual que
[DrawPad](https://github.com/jhonjairo6230/DrawPad).

## Documentación

| Documento | Qué cuenta |
| --------- | ---------- |
| [Uso en el auto](docs/uso-en-el-auto.md) | Qué puntos marcar y cómo seguir la guía. |
| [Cómo funciona la medición](docs/como-funciona-la-medicion.md) | La geometría: de la pisadera al ángulo del respaldo. |
| [Arquitectura](docs/arquitectura.md) | Capas, clases y secuencias. |
| [Compilación e instalación](docs/compilacion-e-instalacion.md) | Del push al iPhone sin Mac. |
| [Flujo de trabajo](docs/flujo-de-trabajo.md) | Git Flow. |
| [Decisiones (ADR)](docs/adr/README.md) | Por qué es así; incluye los ADR adoptados de DrawPad. |
