import Foundation

/// Guarda dónde queda la cabeza respecto al móvil (cámara frontal) como
/// referencia de una posición. Es el complemento de la medición del asiento.
struct UpdateHeadReferenceUseCase {
    private let repository: ProfileRepository
    private let now: () -> Date

    init(repository: ProfileRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    /// - Throws: ``PositionError/profileNotFound`` si ya no existe.
    @discardableResult
    func execute(id: UUID, reference: PostureMeasurement) throws -> DrivingProfile {
        guard var profile = try repository.findProfile(id: id) else {
            throw PositionError.profileNotFound
        }
        profile.head = reference
        profile.updatedAt = now()
        try repository.save(profile)
        return profile
    }
}
