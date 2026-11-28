import ARKit
import SceneKit
import UIKit

/// Mide la cabeza con el **seguimiento facial de ARKit** (cámara frontal).
///
/// Es el único archivo que importa ARKit. Por cada fotograma busca la cara,
/// toma la posición de la cámara y de la cara en el mundo alineado con la
/// gravedad y se las pasa a ``PostureGeometry``, que hace las cuentas sin
/// ARKit.
///
/// La vista previa es un `ARSCNView` que comparte la misma `ARSession`.
@MainActor
final class ARKitHeadTracker: NSObject, HeadTracker, CameraPreviewSource {
    var onSample: ((PostureSample?) -> Void)?

    var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }

    private let session = ARSession()
    private var isRunning = false

    /// Se crea la primera vez que una pantalla la pide, no al arrancar la app.
    private(set) lazy var previewView: UIView = {
        let view = ARSCNView(frame: .zero)
        view.session = session
        view.automaticallyUpdatesLighting = false
        view.rendersCameraGrain = false
        return view
    }()

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard isSupported, !isRunning else { return }
        let configuration = ARFaceTrackingConfiguration()
        // Imprescindible: "arriba" en el mundo debe ser contra la gravedad
        // para que la altura y la profundidad sean de verdad.
        configuration.worldAlignment = .gravity
        configuration.isLightEstimationEnabled = false
        configuration.maximumNumberOfTrackedFaces = 1
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        // La pantalla no se apaga mientras se mide (el conductor no la toca).
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stop() {
        guard isRunning else { return }
        session.pause()
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// Calcula la lectura de un fotograma, o `nil` si no hay cara.
    ///
    /// Se ejecuta dentro del aviso del fotograma y no guarda el `ARFrame`:
    /// retenerlo bloquea la cámara.
    nonisolated static func sample(from frame: ARFrame) -> PostureSample? {
        let face = frame.anchors
            .compactMap { $0 as? ARFaceAnchor }
            .first { $0.isTracked }
        guard let face else { return nil }
        let camera = frame.camera.transform
        return PostureGeometry.sample(
            cameraPosition: Vector3(camera.columns.3),
            cameraRight: Vector3(camera.columns.0),
            cameraUp: Vector3(camera.columns.1),
            cameraBack: Vector3(camera.columns.2),
            headPosition: Vector3(face.transform.columns.3)
        )
    }
}

extension ARKitHeadTracker: ARSessionDelegate {
    /// ARKit llama aquí en el hilo principal (la sesión no tiene otra cola).
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let sample = Self.sample(from: frame)
        MainActor.assumeIsolated {
            onSample?(sample)
        }
    }
}
