import Foundation

/// Cambia el nombre y las notas de una posición, sin tocar su referencia.
struct UpdateNotesUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    /// - Throws: ``PositionError/invalidName`` si el nombre está vacío;
    ///   ``PositionError/profileNotFound`` si ya no existe.
    @discardableResult
    func execute(id: UUID, name: String, notes: String) throws -> DrivingProfile {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw PositionError.invalidName }
        guard var profile = try repository.findProfile(id: id) else {
            throw PositionError.profileNotFound
        }
        profile.name = name
        profile.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try repository.save(profile)
        return profile
    }
}
