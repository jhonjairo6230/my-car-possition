import Foundation

/// Puerto de persistencia de las posiciones guardadas.
///
/// Todos los métodos lanzan ``PositionError/storageFailed`` si falla el
/// almacenamiento.
protocol ProfileRepository {
    /// Todas las posiciones, de la actualizada más recientemente a la más antigua.
    func listProfiles() throws -> [DrivingProfile]

    /// La posición, o `nil` si no existe.
    func findProfile(id: UUID) throws -> DrivingProfile?

    /// Crea la posición o reemplaza la que tenga el mismo `id`.
    func save(_ profile: DrivingProfile) throws

    /// Elimina la posición. No hace nada si no existe.
    func deleteProfile(id: UUID) throws
}
