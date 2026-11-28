import Foundation

/// Las pantallas a las que se puede navegar desde la lista de posiciones.
enum AppRoute: Hashable {
    case newProfile
    case profile(UUID)
    case seatCheck(UUID)
    case headCalibration(UUID)
    case headCheck(UUID)
}

/// Fábricas de pantallas que entrega el ``AppContainer``.
///
/// Presentación no conoce `App`: recibe estas funciones y las vistas de las
/// dos cámaras ya creadas.
struct ScreenFactory {
    /// Vista de la cámara trasera (realidad aumentada del asiento).
    let seatPreview: CameraPreviewSource
    /// Vista de la cámara frontal (cara).
    let headPreview: CameraPreviewSource
    let makeSeatCalibration: () -> SeatCalibrationViewModel
    let makeProfile: (UUID) -> ProfileViewModel
    let makeSeatCheck: (UUID) -> SeatCheckViewModel
    let makeHeadCalibration: (UUID) -> HeadCalibrationViewModel
    let makeHeadCheck: (UUID) -> HeadCheckViewModel
}
