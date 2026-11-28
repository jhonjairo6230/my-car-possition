import Foundation

/// Reemplaza la medición del asiento de una posición (guardar el asiento
/// actual como el nuevo ideal).
struct UpdateSeatUseCase {
    private let repository: ProfileRepository
    private let now: () -> Date

    init(repository: ProfileRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now
    }

    /// - Throws: ``PositionError/profileNotFound`` si ya no existe.
    @discardableResult
    func execute(id: UUID, seat: SeatPosition) throws -> DrivingProfile {
        guard var profile = try repository.findProfile(id: id) else {
            throw PositionError.profileNotFound
        }
        profile.seat = seat
        profile.updatedAt = now()
        try repository.save(profile)
        return profile
    }
}
