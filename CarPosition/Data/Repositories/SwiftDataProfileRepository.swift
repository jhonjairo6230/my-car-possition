import Foundation
import SwiftData

/// Guarda las posiciones en una base de datos local con SwiftData.
///
/// Es el único tipo que conoce SwiftData: el resto de la app usa
/// ``DrivingProfile``. La base de datos vive dentro del contenedor de la app
/// (`Application Support/default.store`) y no sale del móvil.
///
/// Un `ModelContext` no se puede compartir entre hilos: aquí siempre se usa
/// desde el hilo principal, porque quien llama a los casos de uso son los
/// ViewModel (`@MainActor`).
final class SwiftDataProfileRepository: ProfileRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = ModelContext(container)
    }

    /// Crea el contenedor de la base de datos.
    /// - Parameter inMemory: `true` para una base de datos temporal que no
    ///   toca el disco (pruebas).
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: ProfileRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }

    func listProfiles() throws -> [DrivingProfile] {
        try storage {
            let descriptor = FetchDescriptor<ProfileRecord>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map(\.profile)
        }
    }

    func findProfile(id: UUID) throws -> DrivingProfile? {
        try storage { try record(id: id)?.profile }
    }

    func save(_ profile: DrivingProfile) throws {
        try storage {
            if let existing = try record(id: profile.id) {
                existing.update(from: profile)
            } else {
                context.insert(ProfileRecord(profile: profile))
            }
            try context.save()
        }
    }

    func deleteProfile(id: UUID) throws {
        try storage {
            guard let existing = try record(id: id) else { return }
            context.delete(existing)
            try context.save()
        }
    }

    // MARK: - Ayudantes

    private func record(id: UUID) throws -> ProfileRecord? {
        var descriptor = FetchDescriptor<ProfileRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Ejecuta una operación y traduce cualquier error de SwiftData a
    /// ``PositionError/storageFailed``.
    private func storage<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch let error as PositionError {
            throw error
        } catch {
            throw PositionError.storageFailed
        }
    }
}
