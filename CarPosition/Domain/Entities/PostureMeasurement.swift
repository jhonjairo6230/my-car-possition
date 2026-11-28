import Foundation

/// Una medición estable: el resultado de juntar muchas ``PostureSample``.
///
/// Cada fotograma tiene algo de ruido (la cara se mueve, ARKit tiembla
/// unos milímetros), así que nunca se compara un solo fotograma. Se usa la
/// **mediana** de cada distancia, que ignora los fotogramas raros (por
/// ejemplo, al girar la cabeza un instante).
struct PostureMeasurement: Equatable, Codable {
    var depth: Double
    var height: Double
    var lateral: Double
    /// Dirección media de la gravedad vista desde el móvil (longitud 1).
    var deviceGravity: Vector3
    /// Cuántos fotogramas se juntaron.
    var sampleCount: Int

    init(depth: Double, height: Double, lateral: Double, deviceGravity: Vector3, sampleCount: Int) {
        self.depth = depth
        self.height = height
        self.lateral = lateral
        self.deviceGravity = deviceGravity
        self.sampleCount = sampleCount
    }

    /// Junta varias lecturas en una medición, o `nil` si no hay ninguna.
    init?(samples: [PostureSample]) {
        guard !samples.isEmpty else { return nil }
        let gravitySum = samples.reduce(Vector3.zero) { $0 + $1.deviceGravity }
        self.init(
            depth: Self.median(samples.map(\.depth)),
            height: Self.median(samples.map(\.height)),
            lateral: Self.median(samples.map(\.lateral)),
            deviceGravity: gravitySum.normalized ?? Vector3(0, -1, 0),
            sampleCount: samples.count
        )
    }

    /// Valor central de una lista no vacía (media de los dos centrales si el
    /// número de elementos es par).
    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}
