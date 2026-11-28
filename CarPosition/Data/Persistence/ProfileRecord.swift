import Foundation
import SwiftData

/// Fila de la base de datos: cómo SwiftData guarda una ``DrivingProfile``.
///
/// Las medidas se guardan "aplanadas" en columnas `Double` en lugar de como
/// tipos `Codable`: así se ven claras en la base de datos y añadir columnas es
/// una migración automática.
///
/// - Asiento (cámara trasera, en coordenadas del auto): `cushion*`,
///   `backrestLower*`, `backrestUpper*`.
/// - Cabeza (cámara frontal, opcional): `head*`. Si `headSampleCount` es
///   `nil`, la posición no tiene referencia de la cabeza.
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

    var cushionX: Double
    var cushionY: Double
    var cushionZ: Double
    var backrestLowerX: Double
    var backrestLowerY: Double
    var backrestLowerZ: Double
    var backrestUpperX: Double
    var backrestUpperY: Double
    var backrestUpperZ: Double

    var headDepth: Double?
    var headHeight: Double?
    var headLateral: Double?
    var headGravityX: Double?
    var headGravityY: Double?
    var headGravityZ: Double?
    var headSampleCount: Int?

    init(profile: DrivingProfile) {
        id = profile.id
        createdAt = profile.createdAt
        name = profile.name
        notes = profile.notes
        updatedAt = profile.updatedAt
        let seat = profile.seat
        cushionX = seat.cushionFront.x
        cushionY = seat.cushionFront.y
        cushionZ = seat.cushionFront.z
        backrestLowerX = seat.backrestLower.x
        backrestLowerY = seat.backrestLower.y
        backrestLowerZ = seat.backrestLower.z
        backrestUpperX = seat.backrestUpper.x
        backrestUpperY = seat.backrestUpper.y
        backrestUpperZ = seat.backrestUpper.z
        let head = profile.head
        headDepth = head?.depth
        headHeight = head?.height
        headLateral = head?.lateral
        headGravityX = head?.deviceGravity.x
        headGravityY = head?.deviceGravity.y
        headGravityZ = head?.deviceGravity.z
        headSampleCount = head?.sampleCount
    }

    /// Copia en la fila los datos de la entidad (todo menos `id` y `createdAt`).
    func update(from profile: DrivingProfile) {
        name = profile.name
        notes = profile.notes
        updatedAt = profile.updatedAt

        let seat = profile.seat
        cushionX = seat.cushionFront.x
        cushionY = seat.cushionFront.y
        cushionZ = seat.cushionFront.z
        backrestLowerX = seat.backrestLower.x
        backrestLowerY = seat.backrestLower.y
        backrestLowerZ = seat.backrestLower.z
        backrestUpperX = seat.backrestUpper.x
        backrestUpperY = seat.backrestUpper.y
        backrestUpperZ = seat.backrestUpper.z

        let head = profile.head
        headDepth = head?.depth
        headHeight = head?.height
        headLateral = head?.lateral
        headGravityX = head?.deviceGravity.x
        headGravityY = head?.deviceGravity.y
        headGravityZ = head?.deviceGravity.z
        headSampleCount = head?.sampleCount
    }

    /// La entidad de dominio que representa esta fila.
    var profile: DrivingProfile {
        DrivingProfile(
            id: id,
            name: name,
            notes: notes,
            seat: SeatPosition(
                cushionFront: Vector3(cushionX, cushionY, cushionZ),
                backrestLower: Vector3(backrestLowerX, backrestLowerY, backrestLowerZ),
                backrestUpper: Vector3(backrestUpperX, backrestUpperY, backrestUpperZ)
            ),
            head: headMeasurement,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private var headMeasurement: PostureMeasurement? {
        guard let headSampleCount, let headDepth, let headHeight, let headLateral,
              let headGravityX, let headGravityY, let headGravityZ
        else { return nil }
        return PostureMeasurement(
            depth: headDepth,
            height: headHeight,
            lateral: headLateral,
            deviceGravity: Vector3(headGravityX, headGravityY, headGravityZ),
            sampleCount: headSampleCount
        )
    }
}
