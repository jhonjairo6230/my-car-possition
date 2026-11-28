import Foundation
import Observation

/// Estado y acciones de la comprobación con la **cámara frontal**: compara
/// **en vivo** dónde queda la cabeza respecto al móvil con la referencia
/// guardada y dice qué ajustar. Es el complemento de la guía del asiento.
///
/// Usa una ventana con los últimos fotogramas (medio segundo): así el
/// conductor puede mover el asiento mirando la pantalla y ver cómo cambian
/// los centímetros hasta que sale "Todo en su sitio".
@MainActor
@Observable
final class HeadCheckViewModel {
    private(set) var profile: DrivingProfile?
    /// Última comparación; `nil` hasta tener una lectura estable.
    private(set) var evaluation: HeadEvaluation?
    /// `true` si en el último fotograma se veía una cara.
    private(set) var isFaceDetected = false
    var alert: AlertMessage?

    var isSupported: Bool { tracker.isSupported }

    private let profileID: UUID
    private let tracker: HeadTracker
    private let loadProfile: LoadProfileUseCase
    private let evaluatePosition: EvaluateHeadUseCase
    private let updateReference: UpdateHeadReferenceUseCase
    private let windowSize: Int
    private let minimumSamples: Int
    /// Cada cuántos fotogramas se recalcula la comparación en pantalla.
    private let refreshEvery: Int

    @ObservationIgnored private var window: [PostureSample] = []
    @ObservationIgnored private var frameCounter = 0

    init(
        profileID: UUID,
        tracker: HeadTracker,
        loadProfile: LoadProfileUseCase,
        evaluatePosition: EvaluateHeadUseCase,
        updateReference: UpdateHeadReferenceUseCase,
        windowSize: Int = 30,
        minimumSamples: Int = 10,
        refreshEvery: Int = 6
    ) {
        self.profileID = profileID
        self.tracker = tracker
        self.loadProfile = loadProfile
        self.evaluatePosition = evaluatePosition
        self.updateReference = updateReference
        self.windowSize = max(1, windowSize)
        self.minimumSamples = max(1, min(minimumSamples, windowSize))
        self.refreshEvery = max(1, refreshEvery)
    }

    func onAppear() {
        load()
        tracker.onSample = { [weak self] sample in
            self?.receive(sample)
        }
        tracker.start()
    }

    func onDisappear() {
        tracker.stop()
        tracker.onSample = nil
    }

    func load() {
        do {
            profile = try loadProfile.execute(id: profileID)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// Procesa la lectura de un fotograma (la llama el rastreador).
    func receive(_ sample: PostureSample?) {
        guard let sample else {
            if isFaceDetected {
                isFaceDetected = false
            }
            // Si la cara se pierde, se empieza de cero para no mezclar
            // lecturas de antes y de después de moverse.
            window.removeAll()
            return
        }
        if !isFaceDetected {
            isFaceDetected = true
        }
        window.append(sample)
        if window.count > windowSize {
            window.removeFirst(window.count - windowSize)
        }
        frameCounter += 1
        guard frameCounter % refreshEvery == 0 || evaluation == nil else { return }
        evaluate()
    }

    /// Guarda la posición actual como nueva referencia de esta posición.
    func saveCurrentAsReference() {
        guard window.count >= minimumSamples, let current = PostureMeasurement(samples: window) else {
            alert = AlertMessage(error: PositionError.notEnoughSamples)
            return
        }
        do {
            profile = try updateReference.execute(id: profileID, reference: current)
            evaluate()
            alert = .referenceUpdated
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    private func evaluate() {
        guard window.count >= minimumSamples,
              let profile,
              let current = PostureMeasurement(samples: window)
        else { return }
        evaluation = evaluatePosition.execute(current: current, profile: profile)
    }
}
