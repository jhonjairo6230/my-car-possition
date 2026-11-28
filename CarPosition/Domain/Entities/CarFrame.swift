import Foundation

/// Sistema de coordenadas **pegado al auto**, construido con dos puntos del
/// umbral de la puerta.
///
/// ARKit empieza cada sesión con un origen distinto (donde estaba el móvil al
/// abrir la cámara), así que sus coordenadas no sirven para comparar días
/// distintos. El umbral sí: no se mueve, y su línea va de atrás hacia delante
/// del auto. Con él se definen tres ejes, en metros:
///
/// - `x`, **adelante**: del extremo trasero al delantero del umbral.
/// - `y`, **arriba**: la vertical del mundo, corregida para que sea
///   perpendicular al umbral. Así, si el auto está en una pendiente, las
///   medidas siguen siendo "del auto" y no "del suelo".
/// - `z`, **lateral**: perpendicular a los otros dos.
///
/// El origen es el extremo trasero del umbral.
struct CarFrame: Equatable {
    /// Distancia mínima entre los dos puntos del umbral. Con puntos muy
    /// juntos, un error de 1 cm al marcarlos giraría mucho los ejes.
    static let minimumSillLength = 0.3

    let origin: Vector3
    let forward: Vector3
    let up: Vector3
    let side: Vector3

    /// - Throws: ``PositionError/referenceTooShort`` si los puntos están a
    ///   menos de 30 cm; ``PositionError/referenceNotHorizontal`` si la línea
    ///   entre ellos está muy inclinada (no es el umbral).
    init(sillRear: Vector3, sillFront: Vector3, worldUp: Vector3 = .up) throws {
        let line = sillFront - sillRear
        guard line.length >= Self.minimumSillLength, let forward = line.normalized else {
            throw PositionError.referenceTooShort
        }
        let worldUp = worldUp.normalized ?? .up
        // Un umbral no sube más de ~30° (sería una cuesta imposible).
        guard abs(forward.dot(worldUp)) < 0.5,
              let up = (worldUp - forward * forward.dot(worldUp)).normalized
        else {
            throw PositionError.referenceNotHorizontal
        }
        origin = sillRear
        self.forward = forward
        self.up = up
        side = forward.cross(up)
    }

    /// Un punto del mundo de ARKit en coordenadas del auto.
    func local(_ point: Vector3) -> Vector3 {
        let offset = point - origin
        return Vector3(offset.dot(forward), offset.dot(up), offset.dot(side))
    }

    /// Un punto en coordenadas del auto, en el mundo de ARKit (para dibujarlo).
    func world(_ point: Vector3) -> Vector3 {
        origin + worldDirection(point)
    }

    /// Una dirección en coordenadas del auto, en el mundo (sin trasladar).
    func worldDirection(_ direction: Vector3) -> Vector3 {
        forward * direction.x + up * direction.y + side * direction.z
    }

    /// Inclinación del umbral respecto a la horizontal, en grados. Positiva
    /// si el morro del auto está más alto (aparcado cuesta arriba).
    var pitchDegrees: Double {
        asin(max(-1, min(1, forward.dot(.up)))) * 180 / .pi
    }
}
