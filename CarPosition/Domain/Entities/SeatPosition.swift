import Foundation

/// Dónde está el asiento, en coordenadas del auto (``CarFrame``), en metros.
///
/// Se guardan tres puntos y de ellos salen las tres medidas que importan:
///
/// - **Adelante/atrás:** `cushionFront.x`.
/// - **Altura:** `cushionFront.y`.
/// - **Ángulo del respaldo:** la inclinación de la línea `backrestLower` →
///   `backrestUpper` respecto a la vertical del auto (``backrestAngle``).
struct SeatPosition: Equatable {
    var cushionFront: Vector3
    var backrestLower: Vector3
    var backrestUpper: Vector3

    init(cushionFront: Vector3, backrestLower: Vector3, backrestUpper: Vector3) {
        self.cushionFront = cushionFront
        self.backrestLower = backrestLower
        self.backrestUpper = backrestUpper
    }

    /// Convierte puntos marcados en el mundo de ARKit a coordenadas del auto.
    init(frame: CarFrame, cushionFront: Vector3, backrestLower: Vector3, backrestUpper: Vector3) {
        self.init(
            cushionFront: frame.local(cushionFront),
            backrestLower: frame.local(backrestLower),
            backrestUpper: frame.local(backrestUpper)
        )
    }

    /// Grados del respaldo respecto a la vertical del auto. Positivo:
    /// inclinado hacia atrás (lo normal, unos 10–25°).
    var backrestAngle: Double {
        Self.backrestAngle(lower: backrestLower, upper: backrestUpper)
    }

    /// Ángulo de la línea `lower` → `upper` (coordenadas del auto) respecto a
    /// la vertical, en el plano adelante/arriba. Ignora el eje lateral: un
    /// punto marcado un poco a un lado no cambia el ángulo.
    static func backrestAngle(lower: Vector3, upper: Vector3) -> Double {
        let line = upper - lower
        return atan2(-line.x, line.y) * 180 / .pi
    }
}
