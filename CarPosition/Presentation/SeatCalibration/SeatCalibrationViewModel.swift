import Foundation
import Observation

/// Estado y acciones de la calibración del asiento con la cámara trasera:
/// marcar los cinco puntos (``SeatLandmark``) y guardar la posición.
///
/// El usuario apunta la mira a cada punto y pulsa **Marcar**. Se guarda el
/// punto estabilizado (``AimSmoother``), no el de un solo fotograma. Los
/// puntos ya marcados se dibujan en realidad aumentada para comprobar que
/// están donde deben.
@MainActor
@Observable
final class SeatCalibrationViewModel {
    enum Step: Equatable {
        /// Esperando a que se marque este punto.
        case marking(SeatLandmark)
        /// Todos los puntos marcados: falta el nombre.
        case naming
        /// Guardada.
        case saved(DrivingProfile)
    }

    private(set) var step: Step = .marking(.sillRear)
    var name = "Mi posición"
    var notes = ""
    /// `true` si la mira tiene una superficie estable debajo.
    private(set) var isAiming = false
    /// `true` cuando ARKit ya reconoce el entorno.
    private(set) var isTrackingReady = false
    /// Ángulo del respaldo medido, para enseñarlo antes de guardar.
    private(set) var backrestAngle: Double?
    var alert: AlertMessage?

    var isSupported: Bool { scanner.isSupported }

    /// Cuántos puntos van marcados (para "Punto 2 de 5").
    var markedCount: Int {
        switch step {
        case .marking(let landmark): return SeatLandmark.allCases.firstIndex(of: landmark) ?? 0
        case .naming, .saved: return SeatLandmark.allCases.count
        }
    }

    var canUndo: Bool {
        switch step {
        case .marking(let landmark): return landmark.previous != nil
        case .naming: return true
        case .saved: return false
        }
    }

    private let scanner: SeatScanner
    private let createProfile: CreateProfileUseCase
    private let refreshEvery: Int

    @ObservationIgnored private var smoother: AimSmoother
    @ObservationIgnored private var marks: [SeatLandmark: Vector3] = [:]
    @ObservationIgnored private var frameCounter = 0

    init(
        scanner: SeatScanner,
        createProfile: CreateProfileUseCase,
        smoothing: Int = 10,
        refreshEvery: Int = 6
    ) {
        self.scanner = scanner
        self.createProfile = createProfile
        smoother = AimSmoother(capacity: smoothing)
        self.refreshEvery = max(1, refreshEvery)
    }

    func onAppear() {
        scanner.onAim = { [weak self] point in
            self?.receive(point)
        }
        scanner.onTrackingChange = { [weak self] ready in
            self?.isTrackingReady = ready
        }
        scanner.aimedLandmark = currentLandmark
        scanner.start()
        refreshOverlay()
    }

    func onDisappear() {
        scanner.stop()
        scanner.onAim = nil
        scanner.onTrackingChange = nil
        scanner.aimedLandmark = nil
    }

    /// Procesa el punto bajo la mira de un fotograma (lo llama el escáner).
    func receive(_ point: Vector3?) {
        smoother.add(point)
        let aiming = smoother.value != nil
        if isAiming != aiming {
            isAiming = aiming
        }
        frameCounter += 1
    }

    /// Guarda el punto que hay bajo la mira como el punto que se pide ahora.
    func mark() {
        guard case .marking(let landmark) = step else { return }
        guard let point = smoother.value else {
            alert = AlertMessage(error: PositionError.noSurface)
            return
        }
        if landmark == .sillFront, let rear = marks[.sillRear] {
            do {
                _ = try CarFrame(sillRear: rear, sillFront: point)
            } catch {
                alert = AlertMessage(error: error)
                return
            }
        }
        marks[landmark] = point
        // El siguiente punto necesita lecturas nuevas: si no, heredaría este.
        resetAim()
        if let next = landmark.next {
            step = .marking(next)
        } else {
            step = .naming
            backrestAngle = try? seatPosition().backrestAngle
        }
        scanner.aimedLandmark = currentLandmark
        refreshOverlay()
    }

    /// Borra el último punto marcado para volver a marcarlo.
    func undo() {
        switch step {
        case .marking(let landmark):
            guard let previous = landmark.previous else { return }
            marks[previous] = nil
            step = .marking(previous)
        case .naming:
            marks[.backrestUpper] = nil
            backrestAngle = nil
            step = .marking(.backrestUpper)
        case .saved:
            return
        }
        scanner.aimedLandmark = currentLandmark
        refreshOverlay()
    }

    func save() {
        guard step == .naming else { return }
        do {
            let profile = try createProfile.execute(name: name, notes: notes, seat: try seatPosition())
            step = .saved(profile)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    // MARK: - Privado

    private func resetAim() {
        smoother = AimSmoother(capacity: smoother.capacity)
        if isAiming {
            isAiming = false
        }
    }

    private var currentLandmark: SeatLandmark? {
        if case .marking(let landmark) = step { return landmark }
        return nil
    }

    private func seatPosition() throws -> SeatPosition {
        guard let rear = marks[.sillRear], let front = marks[.sillFront],
              let cushion = marks[.cushionFront],
              let lower = marks[.backrestLower], let upper = marks[.backrestUpper]
        else { throw PositionError.incompleteMeasurement }
        let frame = try CarFrame(sillRear: rear, sillFront: front)
        return SeatPosition(frame: frame, cushionFront: cushion, backrestLower: lower, backrestUpper: upper)
    }

    /// Dibuja los puntos ya marcados: el umbral en azul y el asiento en naranja.
    private func refreshOverlay() {
        var overlay = AROverlay()
        for landmark in SeatLandmark.allCases {
            if let point = marks[landmark] {
                overlay.addMarker(point, landmark.isCarReference ? .reference : .current)
            }
        }
        if let rear = marks[.sillRear], let front = marks[.sillFront] {
            overlay.addSegment(rear, front, .reference)
        }
        if let lower = marks[.backrestLower], let upper = marks[.backrestUpper] {
            overlay.addSegment(lower, upper, .current)
        }
        scanner.show(overlay)
    }
}
