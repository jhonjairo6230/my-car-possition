# 0008. Comparar con mediana, tolerancias fijas y veredicto en vivo

- **Estado:** Aceptada
- **Fecha:** 2026-11-25

## Contexto

Un solo fotograma de ARKit tiene ruido (la cara se mueve, la persona
respira, gira la cabeza para mirar la pantalla). Además, el conductor ajusta
el asiento **mientras mira el móvil**, así que la respuesta tiene que
cambiar a medida que mueve la palanca.

## Decisión

1. **Calibrar** junta ~90 fotogramas con cara (1,5 s) tras una **cuenta
   atrás de 3 s** para poner las manos en el volante. La referencia es la
   **mediana** de cada distancia.
2. **Comprobar** es **en vivo**: una ventana de los últimos 30 fotogramas
   (medio segundo), mediana de nuevo, y el veredicto se refresca ~10 veces por
   segundo. Si la cara se pierde, la ventana se vacía.
3. **Tolerancias fijas** (`Tolerance.standard`): 1,5 cm adelante/atrás,
   1,5 cm de altura, 3 cm de lado y 3° de ángulo del móvil.
4. Los ajustes salen **en orden**: primero recolocar el móvil (y entonces
   nada más), después adelante/atrás, altura y lado. En centímetros redondeados,
   nunca menos de 1.
5. Desde la comprobación se puede **guardar la posición actual como nueva
   referencia** (por ejemplo, tras cambiar de zapatos o de cojín).

## Alternativas consideradas

- **Media en lugar de mediana:** un solo fotograma raro (girar la cabeza)
  movería el resultado.
- **Filtro de Kalman o suavizado exponencial:** más fino, pero más difícil de
  explicar y probar; la mediana basta a esta escala.
- **Comprobar con un botón y una foto fija:** obliga a pulsar tras cada
  movimiento de palanca.
- **Tolerancias configurables:** más interfaz; se pueden añadir si las fijas
  resultan demasiado estrictas o laxas en el auto.

## Consecuencias

- El veredicto tarda medio segundo en reaccionar a un cambio.
- Los centímetros son aproximados: sirven para saber cuánto mover, no para
  medir el auto.
- Las tolerancias se podrán ajustar tras probar en el auto real; están en un
  único sitio (`Tolerance`).
