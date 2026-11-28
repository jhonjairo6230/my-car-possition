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

    /// Dónde vive la base de datos (el mismo sitio que usa SwiftData por defecto).
    static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    /// Crea el contenedor de una base de datos temporal que no toca el disco
    /// (pruebas).
    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        guard inMemory else { return try makeContainer(at: storeURL) }
        return try ModelContainer(
            for: ProfileRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Crea el contenedor de la base de datos en un archivo.
    static func makeContainer(at url: URL) throws -> ModelContainer {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return try ModelContainer(for: ProfileRecord.self, configurations: ModelConfiguration(url: url))
    }

    /// Abre la base de datos del disco. Si no se puede (por ejemplo, viene de
    /// una versión cuyo esquema no se sabe migrar), **aparta sus archivos**
    /// (no los borra) y crea una vacía.
    ///
    /// - Returns: el contenedor y, si hubo que apartar la anterior, el error
    ///   que lo causó (para avisar al usuario).
    /// - Throws: si tampoco se puede crear una base de datos vacía.
    static func openRecovering(at url: URL = storeURL) throws -> (container: ModelContainer, setAsideBecause: Error?) {
        do {
            return (try makeContainer(at: url), nil)
        } catch {
            setAside(url)
            return (try makeContainer(at: url), error)
        }
    }

    /// Renombra `default.store` (y sus archivos `-shm` y `-wal`) añadiendo
    /// `.apartado-<fecha>`, para poder recuperarlos a mano si hiciera falta.
    private static func setAside(_ url: URL) {
        let fileManager = FileManager.default
        let stamp = Int(Date().timeIntervalSince1970)
        for suffix in ["", "-shm", "-wal"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            let destination = URL(fileURLWithPath: url.path + ".apartado-\(stamp)" + suffix)
            try? fileManager.moveItem(at: source, to: destination)
        }
    }

    func listProfiles() throws -> [DrivingProfile] {
        try storage {
            let descriptor = FetchDescriptor<ProfileRecord>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).compactMap(\.profile)
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
