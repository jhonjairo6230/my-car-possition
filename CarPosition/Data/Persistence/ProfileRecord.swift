import Foundation
import SwiftData

/// Fila de la base de datos: cómo SwiftData guarda una ``DrivingProfile``.
///
/// La medición se guarda "aplanada" en columnas `Double` en lugar de como un
/// tipo `Codable`: así se ve clara en la base de datos y añadir columnas es
/// una migración automática.
///
/// Toda propiedad que se añada en el futuro debe ser **opcional** o tener
/// valor por defecto, o la base de datos ya instalada no abrirá
/// ([ADR 0006](../../../docs/adr/0006-swiftdata.md)).
@Model
final class ProfileRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var depth: Double
    var height: Double
    var lateral: Double
    var gravityX: Double
    var gravityY: Double
    var gravityZ: Double
    var sampleCount: Int

    init(profile: DrivingProfile) {
        id = profile.id
        name = profile.name
        notes = profile.notes
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
        depth = profile.reference.depth
        height = profile.reference.height
        lateral = profile.reference.lateral
        gravityX = profile.reference.deviceGravity.x
        gravityY = profile.reference.deviceGravity.y
        gravityZ = profile.reference.deviceGravity.z
        sampleCount = profile.reference.sampleCount
    }

    /// Copia en la fila los datos de la entidad (todo menos `id` y `createdAt`).
    func update(from profile: DrivingProfile) {
        name = profile.name
        notes = profile.notes
        updatedAt = profile.updatedAt
        depth = profile.reference.depth
        height = profile.reference.height
        lateral = profile.reference.lateral
        gravityX = profile.reference.deviceGravity.x
        gravityY = profile.reference.deviceGravity.y
        gravityZ = profile.reference.deviceGravity.z
        sampleCount = profile.reference.sampleCount
    }

    /// La entidad de dominio que representa esta fila.
    var profile: DrivingProfile {
        DrivingProfile(
            id: id,
            name: name,
            notes: notes,
            reference: PostureMeasurement(
                depth: depth,
                height: height,
                lateral: lateral,
                deviceGravity: Vector3(gravityX, gravityY, gravityZ),
                sampleCount: sampleCount
            ),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
