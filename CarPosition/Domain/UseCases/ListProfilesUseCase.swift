import Foundation

/// Lista las posiciones guardadas, la más reciente primero.
struct ListProfilesUseCase {
    private let repository: ProfileRepository

    init(repository: ProfileRepository) {
        self.repository = repository
    }

    func execute() throws -> [DrivingProfile] {
        try repository.listProfiles()
    }
}
