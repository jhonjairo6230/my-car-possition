import Foundation
import SwiftData

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. **Todo es `lazy`**: la app
/// crea el contenedor antes de que exista `UIApplication`, y las vistas de
/// UIKit (la cámara) no deben crearse tan pronto.
@MainActor
final class AppContainer {
    /// Argumento de lanzamiento de las pruebas de interfaz: base de datos
    /// vacía en memoria y cámara simulada.
    static let uiTestingArgument = "-uiTesting"

    private let isUITesting = ProcessInfo.processInfo.arguments.contains(AppContainer.uiTestingArgument)

    private(set) lazy var profilesViewModel = ProfilesViewModel(
        listProfiles: ListProfilesUseCase(repository: repository),
        deleteProfile: DeleteProfileUseCase(repository: repository)
    )

    /// La vista de la cámara que muestran las pantallas.
    var cameraPreview: CameraPreviewSource { tracker }

    func makeCalibrationViewModel() -> CalibrationViewModel {
        CalibrationViewModel(
            tracker: tracker,
            createProfile: CreateProfileUseCase(repository: repository)
        )
    }

    func makeCheckViewModel(profileID: UUID) -> CheckViewModel {
        CheckViewModel(
            profileID: profileID,
            tracker: tracker,
            loadProfile: LoadProfileUseCase(repository: repository),
            evaluatePosition: EvaluatePositionUseCase(),
            updateReference: UpdateReferenceUseCase(repository: repository),
            updateNotes: UpdateNotesUseCase(repository: repository)
        )
    }

    // MARK: - Implementaciones concretas

    private lazy var repository: ProfileRepository = {
        do {
            let container = try SwiftDataProfileRepository.makeContainer(inMemory: isUITesting)
            return SwiftDataProfileRepository(container: container)
        } catch {
            // Sin base de datos la app no puede hacer nada útil.
            fatalError("No se pudo abrir la base de datos: \(error)")
        }
    }()

    /// Una sola sesión de cámara para toda la app.
    private lazy var tracker: HeadTracker & CameraPreviewSource = {
        if isUITesting {
            return SimulatedHeadTracker()
        }
        return ARKitHeadTracker()
    }()
}
