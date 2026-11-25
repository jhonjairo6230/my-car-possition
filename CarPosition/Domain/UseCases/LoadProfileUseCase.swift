import Foundation

/// Lee una posición guardada.
struct LoadProfileUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    /// - Throws: ``PositionError/profileNotFound`` si ya no existe.
    func execute(id: UUID) throws -> DrivingProfile {
        guard let profile = try repository.findProfile(id: id) else {
            throw PositionError.profileNotFound
        }
        return profile
    }
}
