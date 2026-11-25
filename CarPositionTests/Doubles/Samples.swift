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

extension DrivingProfile {
    static func sample(
        id: UUID = UUID(),
        name: String = "Mi posición",
        notes: String = "",
        reference: PostureMeasurement = .cm(),
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> DrivingProfile {
        DrivingProfile(id: id, name: name, notes: notes, reference: reference,
                       createdAt: updatedAt, updatedAt: updatedAt)
    }
}
