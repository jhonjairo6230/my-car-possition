import Foundation

/// Cuánto puede alejarse el asiento de la posición guardada sin avisar.
///
/// ARKit marca un punto sobre la tapicería con un error de ~1 cm (menos con
/// LiDAR), y los rieles del asiento avanzan a saltos de 1 a 1,5 cm.
struct SeatTolerance: Equatable {
    /// Metros adelante/atrás.
    var forward: Double
    /// Metros arriba/abajo.
    var height: Double
    /// Grados del respaldo.
    var backrestDegrees: Double

    static let standard = SeatTolerance(forward: 0.015, height: 0.015, backrestDegrees: 2)
}
