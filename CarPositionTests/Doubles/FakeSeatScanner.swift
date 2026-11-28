import Foundation
@testable import CarPosition

/// Escáner falso: las pruebas deciden qué hay bajo la mira con `aim`.
@MainActor
final class FakeSeatScanner: SeatScanner {
    var isSupported = true
    var onAim: ((Vector3?) -> Void)?
    var onTrackingChange: ((Bool) -> Void)?
    var aimedLandmark: SeatLandmark?
    private(set) var isRunning = false
    /// Lo último que se pidió dibujar.
    private(set) var overlay = AROverlay.empty

    func start() { isRunning = true }
    func stop() { isRunning = false }
    func show(_ overlay: AROverlay) { self.overlay = overlay }

    /// Simula `count` fotogramas con la mira sobre `point`.
    func aim(at point: Vector3?, count: Int = 10) {
        for _ in 0..<count {
            onAim?(point)
        }
    }
}
