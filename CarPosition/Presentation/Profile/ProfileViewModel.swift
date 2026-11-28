import Foundation
import Observation

/// Estado y acciones de la ficha de una posición: desde aquí se abre la guía
/// del asiento (cámara trasera) o la comprobación con la cara (cámara
/// frontal), y se editan el nombre y las notas.
@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: DrivingProfile?
    var alert: AlertMessage?

    /// `true` si ya hay referencia de la cabeza (si no, hay que calibrarla).
    var hasHeadReference: Bool { profile?.head != nil }

    private let profileID: UUID
    private let loadProfile: LoadProfileUseCase
    private let updateNotes: UpdateNotesUseCase

    init(profileID: UUID, loadProfile: LoadProfileUseCase, updateNotes: UpdateNotesUseCase) {
        self.profileID = profileID
        self.loadProfile = loadProfile
        self.updateNotes = updateNotes
    }

    var id: UUID { profileID }

    /// Vuelve a leer la posición (al aparecer y al volver de otra pantalla).
    func load() {
        do {
            profile = try loadProfile.execute(id: profileID)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// Cambia el nombre y las notas.
    /// - Returns: `true` si se guardó.
    @discardableResult
    func saveDetails(name: String, notes: String) -> Bool {
        do {
            profile = try updateNotes.execute(id: profileID, name: name, notes: notes)
            return true
        } catch {
            alert = AlertMessage(error: error)
            return false
        }
    }
}
