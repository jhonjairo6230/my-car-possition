import UIKit

/// Escáner de mentira para las pruebas de interfaz.
///
/// El simulador no tiene cámara ni ARKit. Con `-uiTesting`, la app usa este
/// escáner: cuando el ViewModel dice qué punto busca (``aimedLandmark``), la
/// "mira" está justo sobre ese punto de un asiento imaginario. Como el asiento
/// imaginario no cambia, una posición recién guardada coincide consigo misma.
@MainActor
final class SimulatedSeatScanner: SeatScanner, CameraPreviewSource {
    var onAim: ((Vector3?) -> Void)?
    var onTrackingChange: ((Bool) -> Void)?
    var aimedLandmark: SeatLandmark?
    let isSupported = true

    /// Lo último que se pidió dibujar.
    private(set) var overlay = AROverlay.empty
    private var timer: Timer?

    private(set) lazy var previewView: UIView = {
        let label = UILabel()
        label.text = "Cámara trasera simulada"
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .darkGray
        return label
    }()

    /// Un asiento imaginario: el auto mira hacia -z y el umbral mide 1 m.
    static func point(for landmark: SeatLandmark) -> Vector3 {
        switch landmark {
        case .sillRear: return Vector3(0, 0, 0)
        case .sillFront: return Vector3(0, 0, -1)
        case .cushionFront: return Vector3(0.45, 0.30, -0.55)
        case .backrestLower: return Vector3(0.45, 0.45, -0.05)
        case .backrestUpper: return Vector3(0.45, 0.95, 0.10)
        }
    }

    func start() {
        guard timer == nil else { return }
        onTrackingChange?(true)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.onAim?(self.aimedLandmark.map(Self.point(for:)))
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func show(_ overlay: AROverlay) {
        self.overlay = overlay
    }
}
