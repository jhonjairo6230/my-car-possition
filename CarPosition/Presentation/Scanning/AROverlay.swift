import Foundation

/// Lo que se dibuja en realidad aumentada sobre el asiento, en coordenadas
/// del mundo de ARKit (metros).
///
/// Es una **descripción**, no una escena: el ViewModel decide qué dibujar
/// (y se prueba comparando esta estructura) y el escáner de ARKit lo convierte
/// en esferas y barras de SceneKit. Así los ViewModel no importan ARKit.
struct AROverlay: Equatable {
    /// El color lo elige quien dibuja; aquí solo se dice qué significa.
    enum Style: Equatable {
        /// Puntos del auto (umbral).
        case reference
        /// La posición ideal guardada (el "fantasma").
        case target
        /// Lo que se está midiendo ahora y aún no coincide.
        case current
        /// Lo que se está midiendo ahora y ya coincide.
        case match
    }

    struct Marker: Equatable {
        var position: Vector3
        var style: Style
    }

    struct Segment: Equatable {
        var from: Vector3
        var to: Vector3
        var style: Style
    }

    var markers: [Marker] = []
    var segments: [Segment] = []

    static let empty = AROverlay()

    mutating func addMarker(_ position: Vector3, _ style: Style) {
        markers.append(Marker(position: position, style: style))
    }

    mutating func addSegment(_ from: Vector3, _ to: Vector3, _ style: Style) {
        segments.append(Segment(from: from, to: to, style: style))
    }

    /// Añade un arco de círculo entre dos direcciones, como el que dibuja un
    /// transportador: muestra el ángulo que falta para llegar al respaldo ideal.
    ///
    /// - Parameters:
    ///   - center: vértice del ángulo.
    ///   - from: dirección de partida (no hace falta que mida 1).
    ///   - to: dirección de llegada.
    ///   - radius: radio del arco, en metros.
    ///   - steps: tramos rectos con que se aproxima el arco.
    mutating func addArc(center: Vector3, from: Vector3, to: Vector3, radius: Double, style: Style, steps: Int = 16) {
        guard let a = from.normalized, let b = to.normalized, steps > 0 else { return }
        var previous = center + a * radius
        for step in 1...steps {
            let t = Double(step) / Double(steps)
            // Interpolación normalizada: basta para ángulos menores de 180°.
            let direction = (a * (1 - t) + b * t).normalized ?? a
            let point = center + direction * radius
            addSegment(previous, point, style)
            previous = point
        }
    }
}
