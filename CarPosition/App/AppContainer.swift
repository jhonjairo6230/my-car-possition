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

    /// Aviso que se muestra al arrancar si hubo problemas con la base de datos.
    private(set) var startupNotice: AlertMessage?

    private(set) lazy var profilesViewModel: ProfilesViewModel = {
        let viewModel = ProfilesViewModel(
            listProfiles: ListProfilesUseCase(repository: repository),
            deleteProfile: DeleteProfileUseCase(repository: repository)
        )
        // `repository` ya se abrió arriba: si hubo problemas, se enseñan.
        viewModel.alert = startupNotice
        return viewModel
    }()

    /// Todas las pantallas que se abren desde la lista.
    var screens: ScreenFactory {
        ScreenFactory(
            // Las cámaras se crean al abrir su primera pantalla, no al arrancar.
            seatPreview: { [unowned self] in seatScanner },
            headPreview: { [unowned self] in headTracker },
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

    private lazy var repository: ProfileRepository = makeRepository()

    /// Abre la base de datos sin cerrar nunca la app
    /// ([ADR 0012](../../docs/adr/0012-base-de-datos-sin-cierres.md)):
    ///
    /// 1. Lo normal: la del disco.
    /// 2. Si no abre, se aparta y se empieza con una vacía (con aviso).
    /// 3. Si ni así, una en memoria (con aviso: lo guardado no se conserva).
    private func makeRepository() -> ProfileRepository {
        if isUITesting {
            return SwiftDataProfileRepository(container: Self.inMemoryContainer())
        }
        do {
            let (container, setAsideBecause) = try SwiftDataProfileRepository.openRecovering()
            if let setAsideBecause {
                startupNotice = AlertMessage(
                    title: "Se empezó de cero",
                    message: "Las posiciones guardadas no se pudieron leer (seguramente eran de una versión anterior de la app). Se apartaron y la lista empieza vacía.\n\nDetalle: \(setAsideBecause)"
                )
            }
            return SwiftDataProfileRepository(container: container)
        } catch {
            startupNotice = AlertMessage(
                title: "No se pudo abrir la base de datos",
                message: "La app funciona, pero lo que guardes no se conservará al cerrarla.\n\nDetalle: \(error)"
            )
            return SwiftDataProfileRepository(container: Self.inMemoryContainer())
        }
    }

    private static func inMemoryContainer() -> ModelContainer {
        do {
            return try SwiftDataProfileRepository.makeContainer(inMemory: true)
        } catch {
            // Una base de datos en memoria no depende del disco: si esto falla,
            // el esquema mismo está mal y ninguna pantalla podría funcionar.
            fatalError("No se pudo crear la base de datos en memoria: \(error)")
        }
    }

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
