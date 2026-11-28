import Foundation

/// Guarda una posición nueva a partir de una calibración.
struct CreateProfileUseCase {
    private let repository: ProfileRepository
    /// Reloj e identificadores inyectables: en las pruebas se fijan.
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        repository: ProfileRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.repository = repository
        self.now = now
        self.makeID = makeID
    }

    /// - Throws: ``PositionError/invalidName`` si el nombre está vacío.
    @discardableResult
    func execute(name: String, notes: String, reference: PostureMeasurement) throws -> DrivingProfile {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw PositionError.invalidName }
        let date = now()
        let profile = DrivingProfile(
            id: makeID(),
            name: name,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            reference: reference,
            createdAt: date,
            updatedAt: date
        )
        try repository.save(profile)
        return profile
    }
}
