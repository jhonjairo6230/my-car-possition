import Foundation

/// Vector de tres componentes en metros (o adimensional, si es una dirección).
///
/// El dominio no importa `simd` ni ARKit: el adaptador de ARKit convierte sus
/// `simd_float4` a este tipo. Así la geometría se prueba con números simples.
struct Vector3: Equatable, Codable {
    var x: Double
    var y: Double
    var z: Double

    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    static let zero = Vector3(0, 0, 0)
    /// "Arriba" en el mundo de ARKit cuando el mundo se alinea con la gravedad.
    static let up = Vector3(0, 1, 0)

    var length: Double { (x * x + y * y + z * z).squareRoot() }

    /// El vector con longitud 1, o `nil` si es casi nulo.
    var normalized: Vector3? {
        let length = length
        guard length > 1e-9 else { return nil }
        return Vector3(x / length, y / length, z / length)
    }

    /// El mismo vector sin la componente vertical (proyectado al suelo).
    var horizontal: Vector3 { Vector3(x, 0, z) }

    func dot(_ other: Vector3) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    func cross(_ other: Vector3) -> Vector3 {
        Vector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }

    /// Ángulo entre dos direcciones, en grados (de 0 a 180).
    func angle(to other: Vector3) -> Double {
        guard let a = normalized, let b = other.normalized else { return 0 }
        let cosine = min(1, max(-1, a.dot(b)))
        return acos(cosine) * 180 / .pi
    }

    static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static prefix func - (vector: Vector3) -> Vector3 {
        Vector3(-vector.x, -vector.y, -vector.z)
    }

    static func * (vector: Vector3, scale: Double) -> Vector3 {
        Vector3(vector.x * scale, vector.y * scale, vector.z * scale)
    }
}
