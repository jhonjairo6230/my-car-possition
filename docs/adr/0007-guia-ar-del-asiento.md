# 0007. Guiar el asiento con realidad aumentada (cámara trasera), tomando el umbral como referencia

- **Estado:** Aceptada
- **Fecha:** 2026-11-28

## Contexto

Cuando otra persona usa el auto, cambia el asiento: adelante/atrás, altura e
inclinación del respaldo. Se quiere **enfocar el asiento con la cámara
trasera** y que la app **dibuje encima, en realidad aumentada, la posición
ideal guardada**, con el ángulo del respaldo, para ir moviendo las palancas
hasta coincidir.

El problema de fondo: ARKit empieza cada sesión con un origen distinto (donde
estaba el móvil al abrir la cámara). Para comparar el asiento de hoy con el
de hace una semana hace falta algo **fijo del auto** que sirva de regla.

## Decisión

1. **Seguimiento del mundo de ARKit** (`ARWorldTrackingConfiguration`,
   cámara trasera), con detección de planos y, en iPhone con LiDAR,
   reconstrucción de la escena para que los puntos sobre la tapicería sean
   más precisos.
2. **Una mira en el centro de la pantalla.** En cada fotograma se lanza un
   rayo desde el centro contra las superficies reconocidas; el punto que se
   marca es la mediana de los últimos fotogramas (`AimSmoother`). Se marca con
   un botón, no tocando la pantalla: el dedo tapa justo lo que se apunta.
3. **Referencia: los dos extremos del umbral de la puerta del conductor.**
   Con ellos se construye `CarFrame`: `x` adelante (a lo largo del umbral),
   `y` arriba (la gravedad, corregida para ser perpendicular al umbral) y `z`
   lateral. Todo el asiento se guarda en estas coordenadas, así que da igual
   desde dónde se abra la cámara y una pendiente suave no cambia las medidas.
4. **Tres puntos del asiento** (`SeatLandmark`): centro del borde delantero
   del cojín (adelante/atrás y altura) y dos puntos del respaldo, bajo y alto
   (su ángulo respecto a la vertical del auto).
5. **La guía** (`SeatCheckViewModel`): tras marcar el umbral aparece el
   "fantasma" del asiento ideal (bola y barra verdes). Luego, **en vivo**:
   apuntar al cojín dibuja una barra hasta la bola verde y dice cuántos cm
   mover; para el respaldo, se marca el punto bajo y al apuntar al alto se
   dibujan la barra actual, la ideal y **el arco del ángulo** entre ambas.
6. Los ViewModel no conocen ARKit: hablan con el protocolo `SeatScanner` y le
   pasan una descripción de lo que hay que dibujar (`AROverlay`: puntos,
   barras y arcos con un significado, no colores). `ARKitSeatScanner` lo
   convierte en nodos de SceneKit que se ven por encima de la tapicería.
7. Con `-uiTesting` se usa `SimulatedSeatScanner`, que "apunta" siempre al
   punto pedido de un asiento imaginario.

## Alternativas consideradas

- **Pegatina impresa en el umbral** (detección de imágenes de ARKit): la
  referencia sería automática y algo más precisa, pero hay que imprimirla y
  pegarla. Se puede añadir más adelante sin cambiar el resto: solo cambia
  cómo se obtiene el `CarFrame`.
- **Un solo punto de referencia** (por ejemplo, el cerradero del pilar B):
  sitúa el origen, pero no dice hacia dónde es "adelante". Con dos puntos del
  umbral sale la dirección del auto.
- **Medir los ángulos contra la gravedad sin referencia:** sencillo, pero el
  mismo respaldo daría otro ángulo con el auto en una cuesta.
- **Detectar el asiento automáticamente** (planos o malla de LiDAR): el
  respaldo y el cojín no son planos limpios y la malla no existe en todos los
  iPhone. Marcar tres puntos con la mira es más fiable.
- **Tocar la pantalla para marcar:** el dedo tapa el punto y mueve el móvil.

## Consecuencias

- Funciona en cualquier iPhone con ARKit (A9 o posterior); con LiDAR, mejor.
- Cada comprobación empieza marcando el umbral (dos toques, unos segundos).
- La precisión depende de marcar siempre los **mismos** puntos: la guía de
  uso dice exactamente cuáles. Error esperado: ~1 cm y ~1–2°.
- El auto sobre una cuesta muy fuerte o el umbral tapado por una alfombrilla
  alta pueden falsear la referencia; se rechazan los umbrales demasiado
  cortos (< 30 cm) o inclinados (> 30°).
- La geometría (`CarFrame`, `SeatPosition`, `SeatEvaluator`) está en el
  dominio y tiene pruebas, incluida una que comprueba que el mismo asiento
  mide igual desde otro origen de ARKit y con el auto en pendiente. El dibujo
  con SceneKit solo se valida en el auto.
