import Foundation

/// Elimina una posición guardada.
struct DeleteProfileUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute(id: UUID) throws {
        try repository.deleteProfile(id: id)
    }
}
