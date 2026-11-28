import UIKit

/// Rastreador de mentira para las pruebas de interfaz.
///
/// El simulador no tiene cámara ni ARKit. Con `-uiTesting`, la app usa este
/// rastreador: "ve" siempre la misma cabeza a 60 cm, así que una posición
/// recién calibrada coincide consigo misma.
@MainActor
final class SimulatedHeadTracker: HeadTracker, CameraPreviewSource {
    var onSample: ((PostureSample?) -> Void)?
    let isSupported = true

    /// La lectura que se envía en cada "fotograma".
    var sample = PostureSample(depth: 0.6, height: 0.1, lateral: 0, deviceGravity: Vector3(0, -1, 0))

    private var timer: Timer?

    private(set) lazy var previewView: UIView = {
        let label = UILabel()
        label.text = "Cámara simulada"
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .darkGray
        return label
    }()

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.onSample?(self.sample)
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
