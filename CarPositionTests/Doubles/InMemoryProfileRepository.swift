import Foundation
@testable import CarPosition

/// Repositorio falso: guarda las posiciones en memoria y puede simular fallos.
final class InMemoryProfileRepository: ProfileRepository {
    private(set) var profiles: [UUID: DrivingProfile] = [:]
    var error: PositionError?

    init(_ profiles: [DrivingProfile] = []) {
        for profile in profiles {
            self.profiles[profile.id] = profile
        }
    }

    func listProfiles() throws -> [DrivingProfile] {
        if let error { throw error }
        return profiles.values.sorted { $0.updatedAt > $1.updatedAt }
    }

    func findProfile(id: UUID) throws -> DrivingProfile? {
        if let error { throw error }
        return profiles[id]
    }

    func save(_ profile: DrivingProfile) throws {
        if let error { throw error }
        profiles[profile.id] = profile
    }

    func deleteProfile(id: UUID) throws {
        if let error { throw error }
        profiles[id] = nil
    }
}
