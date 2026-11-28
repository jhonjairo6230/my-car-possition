import Foundation

/// Reemplaza la referencia de una posición por una medición nueva
/// (recalibrar sin crear otra posición).
struct UpdateReferenceUseCase {
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
        profile.reference = reference
        profile.updatedAt = now()
        try repository.save(profile)
        return profile
    }
}
