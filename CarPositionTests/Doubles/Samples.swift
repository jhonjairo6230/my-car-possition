import Foundation
@testable import CarPosition

extension PostureSample {
    /// Lectura con valores en **centímetros** para que las pruebas se lean fácil.
    static func cm(depth: Double = 60, height: Double = 10, lateral: Double = 0,
                   gravity: Vector3 = Vector3(0, -1, 0)) -> PostureSample {
        PostureSample(depth: depth / 100, height: height / 100, lateral: lateral / 100, deviceGravity: gravity)
    }
}

extension PostureMeasurement {
    static func cm(depth: Double = 60, height: Double = 10, lateral: Double = 0,
                   gravity: Vector3 = Vector3(0, -1, 0)) -> PostureMeasurement {
        PostureMeasurement(depth: depth / 100, height: height / 100, lateral: lateral / 100,
                           deviceGravity: gravity, sampleCount: 90)
    }
}

extension Vector3 {
    /// Vector en centímetros, para escribir puntos de prueba con números redondos.
    static func cm(_ x: Double, _ y: Double, _ z: Double) -> Vector3 {
        Vector3(x / 100, y / 100, z / 100)
    }
}

/// Un auto de prueba en el mundo de ARKit: mira hacia -z, umbral de 1 m.
///
/// En coordenadas del auto (x adelante, y arriba): el cojín está a 55 cm del
/// extremo trasero del umbral y 30 cm por encima; el respaldo va de (5, 45) a
/// (-10, 95), unos 16,7° hacia atrás.
enum TestCar {
    static let sillRear = Vector3(0, 0, 0)
    static let sillFront = Vector3(0, 0, -1)
    static let cushionFront = Vector3.cm(45, 30, -55)
    static let backrestLower = Vector3.cm(45, 45, -5)
    static let backrestUpper = Vector3.cm(45, 95, 10)

    static var frame: CarFrame {
        try! CarFrame(sillRear: sillRear, sillFront: sillFront)
    }

    /// El asiento de prueba, en coordenadas del auto.
    static var seat: SeatPosition {
        SeatPosition(frame: frame, cushionFront: cushionFront, backrestLower: backrestLower, backrestUpper: backrestUpper)
    }

    /// Un punto del mundo desplazado en coordenadas del auto (cm).
    static func moved(_ point: Vector3, forward: Double = 0, up: Double = 0) -> Vector3 {
        point + frame.worldDirection(.cm(forward, up, 0))
    }
}

extension DrivingProfile {
    static func sample(
        id: UUID = UUID(),
        name: String = "Mi posición",
        notes: String = "",
        seat: SeatPosition = TestCar.seat,
        head: PostureMeasurement? = .cm(),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> DrivingProfile {
        DrivingProfile(id: id, name: name, notes: notes, seat: seat, head: head,
                       createdAt: updatedAt, updatedAt: updatedAt)
    }
}
