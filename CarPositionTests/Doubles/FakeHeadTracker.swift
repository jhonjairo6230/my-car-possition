import Foundation
@testable import CarPosition

/// Rastreador falso: las pruebas deciden qué "ve" la cámara con `emit`.
@MainActor
final class FakeHeadTracker: HeadTracker {
    var isSupported = true
    var onSample: ((PostureSample?) -> Void)?
    private(set) var isRunning = false

    func start() { isRunning = true }
    func stop() { isRunning = false }

    /// Simula `count` fotogramas con la misma lectura.
    func emit(_ sample: PostureSample?, count: Int = 1) {
        for _ in 0..<count {
            onSample?(sample)
        }
    }
}
