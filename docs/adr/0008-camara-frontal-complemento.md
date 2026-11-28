# 0008. Comprobar con la cara (cámara frontal) como complemento

- **Estado:** Aceptada
- **Fecha:** 2026-11-25

## Contexto

La guía principal mide el asiento con la cámara trasera
([ADR 0007](0007-guia-ar-del-asiento.md)). Como complemento, se quiere una
comprobación sentado: al final lo que importa es **dónde queda la cabeza del
conductor**: de eso dependen la visión, la distancia a los pedales y al
volante y lo que se ve en los espejos. Hace falta medirla con precisión de
1–2 cm, con un iPhone, sin accesorios y sin Mac
([ADR 0004](0004-compilar-sin-mac.md)).

## Decisión

0. Es un **complemento opcional** de cada posición: se calibra desde la ficha
   de la posición ("Calibrar con mi cara") y se guarda junto al asiento
   (`DrivingProfile.head`).
1. **Seguimiento facial de ARKit** (`ARFaceTrackingConfiguration`, cámara
   frontal). ARKit da la posición 3D de la cara en metros, ~60 veces por
   segundo, con un error de pocos milímetros a 50–80 cm.
2. **El móvil va siempre en el mismo soporte del auto** (rejilla o
   salpicadero) y es la regla de medir: todo se mide **desde la cámara**.
3. Las cuentas se hacen en el mundo de ARKit **alineado con la gravedad**
   (`worldAlignment = .gravity`), con tres distancias que no dependen de si el
   móvil está en vertical u horizontal: **profundidad** (horizontal, por el eje
   de la cámara), **altura** (vertical de verdad) y **lado** (horizontal,
   hacia la derecha del conductor). Viven en `PostureGeometry`, en el dominio,
   sin ARKit.
4. Se guarda también **la dirección de la gravedad vista desde el móvil**.
   Si al comprobar ha cambiado más de 3°, el soporte se movió y la app pide
   recolocar el móvil antes de dar ningún otro consejo.
5. ARKit vive solo en `ARKitHeadTracker`, detrás del protocolo `HeadTracker`.
   Hay **una sola sesión** para toda la app.
6. Con `-uiTesting` se usa `SimulatedHeadTracker`, que "ve" siempre la misma
   cabeza, para que las pruebas de interfaz recorran el flujo completo en el
   simulador.
7. Los espejos y el volante no se miden: cada posición tiene **notas**
   ("Volante: 2ª muesca").

## Alternativas consideradas

- **Solo la guía con la cámara trasera:** mide el asiento, pero no la
  cabeza; un cojín más grueso o otros zapatos cambian la postura sin mover
  el asiento.
- **Detección de cuerpo (`ARBodyTrackingConfiguration`):** cámara trasera y
  cuerpo entero a la vista; imposible dentro de un auto.
- **Vision (puntos de la cara en 2D) con la cámara normal:** funciona en más
  iPhones, pero sin profundidad: la distancia saldría del tamaño de la cara y
  la precisión sería de varios centímetros.
- **Fotos de referencia para comparar a ojo:** sin cuentas, pero sin decir
  cuánto mover ni hacia dónde.
- **Medir desde la posición de la cámara sin gravedad** (ejes del móvil):
  más simple, pero un soporte algo girado cambiaría todas las medidas y no
  habría forma de saber si fue el asiento o el móvil.

## Consecuencias

- Hace falta un iPhone con seguimiento facial (XS/XR o posterior, o con
  Face ID). En otros dispositivos y en el simulador la app lo dice y no mide.
- **El soporte del móvil es parte de la medida.** Si se mueve de sitio (no
  solo de ángulo) la app no lo nota; la guía de uso insiste en dejarlo fijo.
- Profundidad y altura dependen también del **respaldo**: inclinarlo mueve la
  cabeza hacia atrás y abajo. La app da el ajuste del asiento y avisa de que
  el respaldo puede ser la causa.
- Gafas de sol, gorra o mala luz pueden impedir ver la cara; la calibración se
  rinde tras unos 10 s sin cara.
- La medición real **solo se valida en el auto**: ni el CI ni el simulador
  tienen cámara. Las cuentas sí tienen pruebas unitarias.
- Las imágenes de la cámara no se guardan; solo tres números y una dirección.
