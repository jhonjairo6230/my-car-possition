import Foundation
import SwiftData

/// *Composition root*: el único lugar donde se crean las implementaciones
/// concretas y se conectan entre sí (inyección de dependencias manual).
///
/// El resto del código solo conoce protocolos. **Todo es `lazy`**: la app
/// crea el contenedor antes de que exista `UIApplication`, y las vistas de
/// UIKit (las cámaras) no deben crearse tan pronto.
@MainActor
final class AppContainer {
    /// Argumento de lanzamiento de las pruebas de interfaz: base de datos
    /// vacía en memoria y cámaras simuladas.
    static let uiTestingArgument = "-uiTesting"

    private let isUITesting = ProcessInfo.processInfo.arguments.contains(AppContainer.uiTestingArgument)

    private(set) lazy var profilesViewModel = ProfilesViewModel(
        listProfiles: ListProfilesUseCase(repository: repository),
        deleteProfile: DeleteProfileUseCase(repository: repository)
    )

    /// Todas las pantallas que se abren desde la lista.
    var screens: ScreenFactory {
        ScreenFactory(
            seatPreview: seatScanner,
            headPreview: headTracker,
            makeSeatCalibration: { [unowned self] in makeSeatCalibrationViewModel() },
            makeProfile: { [unowned self] in makeProfileViewModel(profileID: $0) },
            makeSeatCheck: { [unowned self] in makeSeatCheckViewModel(profileID: $0) },
            makeHeadCalibration: { [unowned self] in makeHeadCalibrationViewModel(profileID: $0) },
            makeHeadCheck: { [unowned self] in makeHeadCheckViewModel(profileID: $0) }
        )
    }

    func makeSeatCalibrationViewModel() -> SeatCalibrationViewModel {
        SeatCalibrationViewModel(
            scanner: seatScanner,
            createProfile: CreateProfileUseCase(repository: repository)
        )
    }

    func makeProfileViewModel(profileID: UUID) -> ProfileViewModel {
        ProfileViewModel(
            profileID: profileID,
            loadProfile: LoadProfileUseCase(repository: repository),
            updateNotes: UpdateNotesUseCase(repository: repository)
        )
    }

    func makeSeatCheckViewModel(profileID: UUID) -> SeatCheckViewModel {
        SeatCheckViewModel(
            profileID: profileID,
            scanner: seatScanner,
            loadProfile: LoadProfileUseCase(repository: repository),
            checkSeat: CheckSeatUseCase(),
            updateSeat: UpdateSeatUseCase(repository: repository)
        )
    }

    func makeHeadCalibrationViewModel(profileID: UUID) -> HeadCalibrationViewModel {
        HeadCalibrationViewModel(
            profileID: profileID,
            tracker: headTracker,
            updateHeadReference: UpdateHeadReferenceUseCase(repository: repository)
        )
    }

    func makeHeadCheckViewModel(profileID: UUID) -> HeadCheckViewModel {
        HeadCheckViewModel(
            profileID: profileID,
            tracker: headTracker,
            loadProfile: LoadProfileUseCase(repository: repository),
            evaluatePosition: EvaluateHeadUseCase(),
            updateReference: UpdateHeadReferenceUseCase(repository: repository)
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

    /// Cámara trasera con realidad aumentada (guía del asiento).
    private lazy var seatScanner: SeatScanner & CameraPreviewSource = {
        if isUITesting {
            return SimulatedSeatScanner()
        }
        return ARKitSeatScanner()
    }()

    /// Cámara frontal con seguimiento facial (complemento).
    private lazy var headTracker: HeadTracker & CameraPreviewSource = {
        if isUITesting {
            return SimulatedHeadTracker()
        }
        return ARKitHeadTracker()
    }()
}
