import Foundation

/// Lo que los ViewModel necesitan de quien mide la cabeza del conductor.
///
/// Es un *puerto* de la capa de presentación: los ViewModel hablan con este
/// protocolo y no con ARKit. Así se prueban con un rastreador falso
/// (`FakeHeadTracker` en las pruebas) sin cámara ni iPhone.
///
/// Hay una sola instancia en toda la app (ARKit solo permite una sesión de
/// cámara a la vez): cada pantalla la "toma" en `onAppear` poniendo su
/// `onSample` y la suelta en `onDisappear`.
@MainActor
protocol HeadTracker: AnyObject {
    /// `false` si el dispositivo no puede seguir caras (simulador, iPhone sin
    /// cámara frontal compatible).
    var isSupported: Bool { get }

    /// Se llama en cada fotograma (unas 60 veces por segundo) con la lectura,
    /// o con `nil` si en ese fotograma no se ve ninguna cara.
    var onSample: ((PostureSample?) -> Void)? { get set }

    /// Enciende la cámara. No hace nada si ya está encendida o no hay soporte.
    func start()
    /// Apaga la cámara.
    func stop()
}
