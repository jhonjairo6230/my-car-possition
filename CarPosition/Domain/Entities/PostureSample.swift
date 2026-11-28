import Foundation

/// Una lectura instantánea (un fotograma) de dónde está la cabeza del
/// conductor respecto al móvil.
///
/// Las distancias están en **metros** y se miden desde la cámara frontal:
///
/// - `depth`: distancia horizontal hacia el conductor. Crece si el asiento va
///   hacia atrás.
/// - `height`: altura de la cabeza sobre la cámara, siguiendo la gravedad.
///   Crece si el asiento sube.
/// - `lateral`: desplazamiento hacia la **derecha del conductor**.
///
/// `deviceGravity` es la dirección de la gravedad vista desde el móvil. No
/// depende de la cabeza: sirve para saber si el soporte del móvil cambió de
/// ángulo desde la calibración.
struct PostureSample: Equatable {
    var depth: Double
    var height: Double
    var lateral: Double
    var deviceGravity: Vector3
}
