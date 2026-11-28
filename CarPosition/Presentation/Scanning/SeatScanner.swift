import Foundation

/// Lo que los ViewModel del asiento necesitan de la cámara trasera con
/// realidad aumentada.
///
/// Es un *puerto* de la capa de presentación, como ``HeadTracker`` para la
/// cámara frontal: los ViewModel hablan con este protocolo y no con ARKit, y
/// se prueban con un escáner falso (`FakeSeatScanner`).
///
/// Hay una sola instancia en toda la app. Cada pantalla la toma en `onAppear`
/// y la suelta en `onDisappear`.
@MainActor
protocol SeatScanner: AnyObject {
    /// `false` si el dispositivo no puede hacer seguimiento del mundo.
    var isSupported: Bool { get }

    /// Se llama en cada fotograma con el punto del mundo que hay bajo la mira
    /// (el centro de la pantalla), o `nil` si la mira no toca ninguna
    /// superficie reconocida.
    var onAim: ((Vector3?) -> Void)? { get set }

    /// Se llama cuando ARKit gana (`true`) o pierde (`false`) el seguimiento
    /// del entorno. Mientras es `false`, las medidas no son fiables.
    var onTrackingChange: ((Bool) -> Void)? { get set }

    /// Qué punto está buscando el usuario ahora. El escáner real lo ignora;
    /// el simulado de las pruebas de interfaz lo usa para "apuntar" a él.
    var aimedLandmark: SeatLandmark? { get set }

    /// Enciende la cámara trasera. No hace nada si ya está encendida.
    func start()
    /// Apaga la cámara.
    func stop()
    /// Reemplaza lo dibujado en realidad aumentada.
    func show(_ overlay: AROverlay)
}
