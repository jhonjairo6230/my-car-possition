import Foundation

/// Lo que hay que tocar para volver a la posición guardada.
///
/// Lo producen las dos comprobaciones: la del asiento con la cámara trasera
/// (``SeatEvaluator``) y la de la cabeza con la cámara frontal
/// (``HeadEvaluator``). Los centímetros y grados son aproximados y siempre al
/// menos 1.
enum Adjustment: Equatable {
    /// El soporte del móvil cambió de ángulo: el resto de medidas no es fiable.
    case realignPhone(degrees: Int)
    case moveSeatForward(centimeters: Int)
    case moveSeatBackward(centimeters: Int)
    case raiseSeat(centimeters: Int)
    case lowerSeat(centimeters: Int)
    /// El conductor está más a su derecha: debe moverse a su izquierda.
    case shiftLeft(centimeters: Int)
    /// El conductor está más a su izquierda: debe moverse a su derecha.
    case shiftRight(centimeters: Int)
    /// El respaldo está más recto que el guardado: hay que inclinarlo hacia atrás.
    case reclineBackrest(degrees: Int)
    /// El respaldo está más inclinado que el guardado: hay que enderezarlo.
    case straightenBackrest(degrees: Int)

    /// Metros → centímetros enteros, al menos 1.
    static func centimeters(_ meters: Double) -> Int {
        max(1, Int((abs(meters) * 100).rounded()))
    }

    /// Grados enteros, al menos 1.
    static func degrees(_ value: Double) -> Int {
        max(1, Int(abs(value).rounded()))
    }
}
