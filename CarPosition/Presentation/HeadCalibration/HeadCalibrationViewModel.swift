import Foundation
import Observation

/// Estado y acciones de la calibración con la **cámara frontal**: guardar
/// dónde queda la cabeza respecto al móvil como complemento de una posición
/// que ya tiene el asiento medido.
///
/// El flujo es: el conductor se acomoda, pulsa **Calibrar**, tiene unos
/// segundos de cuenta atrás para poner las manos en el volante y mirar al
/// frente, y luego se juntan unos 90 fotogramas (1,5 s) en una
/// ``PostureMeasurement``.
@MainActor
@Observable
final class HeadCalibrationViewModel {
    enum Phase: Equatable {
        /// Esperando a que el conductor pulse "Calibrar".
        case ready
        /// Cuenta atrás antes de medir.
        case countdown(secondsLeft: Int)
        /// Midiendo. `progress` va de 0 a 1.
        case capturing(progress: Double)
        /// Terminado: la posición ya está guardada.
        case saved(DrivingProfile)
    }

    private(set) var phase: Phase = .ready
    /// `true` si en el último fotograma se veía una cara.
    private(set) var isFaceDetected = false
    /// Distancia aproximada a la cara, en centímetros, para orientar al
    /// colocar el móvil. Se refresca unas 10 veces por segundo.
    private(set) var distanceCentimeters: Int?
    var alert: AlertMessage?

    var isSupported: Bool { tracker.isSupported }

    var canStart: Bool {
        phase == .ready && isSupported
    }

    private let profileID: UUID
    private let tracker: HeadTracker
    private let updateHeadReference: UpdateHeadReferenceUseCase
    private let countdownSeconds: Int
    private let samplesNeeded: Int
    /// Fotogramas (con o sin cara) que se esperan antes de rendirse.
    private let maxFrames: Int
    /// Cada cuántos fotogramas se refresca la distancia en pantalla.
    private let refreshEvery: Int
    private let sleep: (Duration) async throws -> Void

    @ObservationIgnored private var collected: [PostureSample] = []
    @ObservationIgnored private var framesWaited = 0
    @ObservationIgnored private var frameCounter = 0
    @ObservationIgnored private var countdownTask: Task<Void, Never>?

    init(
        profileID: UUID,
        tracker: HeadTracker,
        updateHeadReference: UpdateHeadReferenceUseCase,
        countdownSeconds: Int = 3,
        samplesNeeded: Int = 90,
        maxFrames: Int = 600,
        refreshEvery: Int = 6,
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.profileID = profileID
        self.tracker = tracker
        self.updateHeadReference = updateHeadReference
        self.countdownSeconds = countdownSeconds
        self.samplesNeeded = samplesNeeded
        self.maxFrames = maxFrames
        self.refreshEvery = max(1, refreshEvery)
        self.sleep = sleep
    }

    /// Toma el rastreador y enciende la cámara.
    func onAppear() {
        tracker.onSample = { [weak self] sample in
            self?.receive(sample)
        }
        tracker.start()
    }

    /// Apaga la cámara y abandona una calibración a medias.
    func onDisappear() {
        cancelCapture()
        tracker.stop()
        tracker.onSample = nil
    }

    /// Empieza la cuenta atrás. Al terminar, la medición empieza sola.
    /// - Returns: la tarea de la cuenta atrás (las pruebas la esperan).
    @discardableResult
    func startCapture() -> Task<Void, Never>? {
        guard phase == .ready else { return nil }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runCountdown()
        }
        countdownTask = task
        return task
    }

    /// Detiene la cuenta atrás o la medición en curso.
    func cancelCapture() {
        countdownTask?.cancel()
        countdownTask = nil
        switch phase {
        case .countdown, .capturing:
            phase = .ready
        case .ready, .saved:
            break
        }
    }

    /// Procesa la lectura de un fotograma (la llama el rastreador).
    func receive(_ sample: PostureSample?) {
        let detected = sample != nil
        if isFaceDetected != detected {
            isFaceDetected = detected
        }
        frameCounter += 1
        if frameCounter % refreshEvery == 0 || sample == nil {
            let distance = sample.map { Int(($0.depth * 100).rounded()) }
            if distanceCentimeters != distance {
                distanceCentimeters = distance
            }
        }

        guard case .capturing = phase else { return }
        framesWaited += 1
        if let sample {
            collected.append(sample)
        }
        if collected.count >= samplesNeeded {
            finish()
        } else if framesWaited >= maxFrames {
            phase = .ready
            alert = AlertMessage(error: PositionError.faceNotFound)
        } else if frameCounter % refreshEvery == 0 {
            phase = .capturing(progress: Double(collected.count) / Double(samplesNeeded))
        }
    }

    // MARK: - Privado

    private func runCountdown() async {
        for secondsLeft in stride(from: countdownSeconds, through: 1, by: -1) {
            phase = .countdown(secondsLeft: secondsLeft)
            do {
                try await sleep(.seconds(1))
            } catch {
                return // Cancelada.
            }
            guard phase == .countdown(secondsLeft: secondsLeft) else { return }
        }
        collected = []
        framesWaited = 0
        phase = .capturing(progress: 0)
    }

    private func finish() {
        guard let measurement = PostureMeasurement(samples: collected) else { return }
        collected = []
        do {
            let profile = try updateHeadReference.execute(id: profileID, reference: measurement)
            phase = .saved(profile)
        } catch {
            phase = .ready
            alert = AlertMessage(error: error)
        }
    }
}
