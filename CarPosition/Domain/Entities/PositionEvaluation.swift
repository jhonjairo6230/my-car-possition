import Foundation

/// Lo que hay que tocar para volver a la posición de referencia.
///
/// Los centímetros son aproximados y siempre al menos 1.
enum Adjustment: Equatable {
    /// El soporte del móvil cambió de ángulo: el resto de medidas no es fiable.
    case realignPhone(degrees: Int)
    /// La cabeza está más lejos que en la referencia.
    case moveSeatForward(centimeters: Int)
    /// La cabeza está más cerca que en la referencia.
    case moveSeatBackward(centimeters: Int)
    /// La cabeza está más baja que en la referencia.
    case raiseSeat(centimeters: Int)
    /// La cabeza está más alta que en la referencia.
    case lowerSeat(centimeters: Int)
    /// El conductor está más a su derecha: debe moverse a su izquierda.
    case shiftLeft(centimeters: Int)
    /// El conductor está más a su izquierda: debe moverse a su derecha.
    case shiftRight(centimeters: Int)
}

/// Resultado de comparar la posición actual con la de referencia.
struct PositionEvaluation: Equatable {
    /// Metros. Positivo: la cabeza está **más lejos** del móvil.
    var depthOffset: Double
    /// Metros. Positivo: la cabeza está **más alta**.
    var heightOffset: Double
    /// Metros. Positivo: el conductor está **más a su derecha**.
    var lateralOffset: Double
    /// Grados que giró el móvil respecto a la calibración.
    var phoneTiltChange: Double
    /// Qué ajustar, en orden. Vacía si todo está dentro de la tolerancia.
    var adjustments: [Adjustment]

    /// `true` si la posición coincide con la referencia.
    var isMatch: Bool { adjustments.isEmpty }
}
