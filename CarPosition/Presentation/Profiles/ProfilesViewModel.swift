import Foundation
import Observation

/// Estado y acciones de la lista de posiciones guardadas (patrón MVVM).
@MainActor
@Observable
final class ProfilesViewModel {
    /// Posiciones a mostrar, de la actualizada más recientemente a la más antigua.
    private(set) var profiles: [DrivingProfile] = []
    var alert: AlertMessage?

    private let listProfiles: ListProfilesUseCase
    private let deleteProfile: DeleteProfileUseCase

    init(listProfiles: ListProfilesUseCase, deleteProfile: DeleteProfileUseCase) {
        self.listProfiles = listProfiles
        self.deleteProfile = deleteProfile
    }

    /// Vuelve a leer la lista (al aparecer y al volver de otra pantalla).
    func load() {
        perform { profiles = try listProfiles.execute() }
    }

    func delete(id: UUID) {
        perform {
            try deleteProfile.execute(id: id)
            profiles = try listProfiles.execute()
        }
    }

    /// Ejecuta una operación y convierte cualquier error en una alerta.
    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            alert = AlertMessage(error: error)
        }
    }
}
