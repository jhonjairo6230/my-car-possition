import Foundation

/// Estabiliza el punto bajo la mira de la cámara.
///
/// Cada fotograma, ARKit calcula dónde toca la mira la superficie, y ese
/// punto tiembla unos milímetros (la mano se mueve, la tapicería no es lisa).
/// Se usa la **mediana** de cada coordenada de los últimos fotogramas: ignora
/// los saltos sueltos, por ejemplo cuando la mira pasa un instante por un
/// borde.
struct AimSmoother {
    let capacity: Int
    private(set) var points: [Vector3] = []

    init(capacity: Int = 10) {
        self.capacity = max(1, capacity)
    }

    /// Añade la lectura de un fotograma. `nil` (la mira no toca nada) vacía la
    /// ventana para no mezclar superficies distintas.
    mutating func add(_ point: Vector3?) {
        guard let point else {
            points.removeAll()
            return
        }
        points.append(point)
        if points.count > capacity {
            points.removeFirst(points.count - capacity)
        }
    }

    /// El punto estable, o `nil` si aún no hay suficientes lecturas (la mitad
    /// de la ventana).
    var value: Vector3? {
        guard points.count >= (capacity + 1) / 2 else { return nil }
        return Vector3(
            PostureMeasurement.median(points.map(\.x)),
            PostureMeasurement.median(points.map(\.y)),
            PostureMeasurement.median(points.map(\.z))
        )
    }
}
