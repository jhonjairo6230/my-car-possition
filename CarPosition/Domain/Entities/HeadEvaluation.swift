import Foundation

/// Resultado de comparar la cabeza (cámara frontal) con la referencia.
struct HeadEvaluation: Equatable {
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
