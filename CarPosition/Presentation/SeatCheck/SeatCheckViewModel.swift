import Foundation
import Observation

/// Estado y acciones de la guía del asiento con realidad aumentada.
///
/// Pasos:
///
/// 1. **Referencia:** marcar los dos extremos del umbral. Con ellos se
///    reconstruye el sistema del auto (``CarFrame``) y aparece el "fantasma"
///    del asiento ideal: una esfera verde donde debe quedar el borde del cojín
///    y una barra verde con el ángulo del respaldo.
/// 2. **Cojín (en vivo):** se apunta al borde delantero del cojín y, mientras
///    se mueve la palanca, se dibuja una barra hasta el fantasma y se dice
///    cuánto falta ("Adelanta el asiento 3 cm").
/// 3. **Respaldo:** se marca el punto bajo del respaldo y se apunta al alto.
///    Se dibuja el ángulo actual, el ideal y el arco entre ambos, en vivo.
/// 4. **Resumen.**
@MainActor
@Observable
final class SeatCheckViewModel {
    enum Phase: Equatable {
        case reference(SeatLandmark)
        case cushion
        case backrestLower
        case backrestUpper
        case done
    }

    private(set) var phase: Phase = .reference(.sillRear)
    private(set) var profile: DrivingProfile?
    /// Último resultado del cojín (en vivo durante `.cushion`).
    private(set) var cushionCheck: CushionCheck?
    /// Último resultado del respaldo (en vivo durante `.backrestUpper`).
    private(set) var backrestCheck: BackrestCheck?
    private(set) var isAiming = false
    private(set) var isTrackingReady = false
    var alert: AlertMessage?

    var isSupported: Bool { scanner.isSupported }

    /// `true` si se puede pulsar "Marcar" en esta fase.
    var needsMark: Bool {
        switch phase {
        case .reference, .backrestLower: return true
        case .cushion, .backrestUpper, .done: return false
        }
    }

    /// `true` si el asiento medido se puede guardar como el nuevo ideal.
    var canSaveAsIdeal: Bool {
        phase == .done && lastCushion != nil && lastBackrest != nil
    }

    private let profileID: UUID
    private let scanner: SeatScanner
    private let loadProfile: LoadProfileUseCase
    private let checkSeat: CheckSeatUseCase
    private let updateSeat: UpdateSeatUseCase
    private let refreshEvery: Int

    @ObservationIgnored private var smoother: AimSmoother
    @ObservationIgnored private var sillRear: Vector3?
    @ObservationIgnored private var sillFront: Vector3?
    @ObservationIgnored private var frame: CarFrame?
    @ObservationIgnored private var backrestLower: Vector3?
    /// Últimas medidas en vivo, en coordenadas del auto.
    @ObservationIgnored private var lastCushion: Vector3?
    @ObservationIgnored private var lastBackrest: (lower: Vector3, upper: Vector3)?
    @ObservationIgnored private var frameCounter = 0

    init(
        profileID: UUID,
        scanner: SeatScanner,
        loadProfile: LoadProfileUseCase,
        checkSeat: CheckSeatUseCase,
        updateSeat: UpdateSeatUseCase,
        smoothing: Int = 10,
        refreshEvery: Int = 6
    ) {
        self.profileID = profileID
        self.scanner = scanner
        self.loadProfile = loadProfile
        self.checkSeat = checkSeat
        self.updateSeat = updateSeat
        smoother = AimSmoother(capacity: smoothing)
        self.refreshEvery = max(1, refreshEvery)
    }

    func onAppear() {
        load()
        scanner.onAim = { [weak self] point in
            self?.receive(point)
        }
        scanner.onTrackingChange = { [weak self] ready in
            self?.isTrackingReady = ready
        }
        scanner.aimedLandmark = aimedLandmark
        scanner.start()
        refreshOverlay()
    }

    func onDisappear() {
        scanner.stop()
        scanner.onAim = nil
        scanner.onTrackingChange = nil
        scanner.aimedLandmark = nil
    }

    func load() {
        do {
            profile = try loadProfile.execute(id: profileID)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// Procesa el punto bajo la mira de un fotograma (lo llama el escáner).
    func receive(_ point: Vector3?) {
        smoother.add(point)
        let aiming = smoother.value != nil
        if isAiming != aiming {
            isAiming = aiming
        }
        frameCounter += 1
        guard frameCounter % refreshEvery == 0 else { return }
        evaluateLive()
        refreshOverlay()
    }

    /// Marca el punto que se pide en las fases que lo necesitan.
    func mark() {
        guard needsMark else { return }
        guard let point = smoother.value else {
            alert = AlertMessage(error: PositionError.noSurface)
            return
        }
        switch phase {
        case .reference(.sillRear):
            sillRear = point
            phase = .reference(.sillFront)
        case .reference:
            guard let sillRear else { return }
            do {
                frame = try CarFrame(sillRear: sillRear, sillFront: point)
                sillFront = point
                phase = .cushion
            } catch {
                alert = AlertMessage(error: error)
                return
            }
        case .backrestLower:
            backrestLower = point
            phase = .backrestUpper
        case .cushion, .backrestUpper, .done:
            return
        }
        // El siguiente punto necesita lecturas nuevas: si no, heredaría este.
        resetAim()
        scanner.aimedLandmark = aimedLandmark
        evaluateLive()
        refreshOverlay()
    }

    /// Pasa del cojín al respaldo, y del respaldo al resumen.
    func next() {
        switch phase {
        case .cushion: phase = .backrestLower
        case .backrestUpper: phase = .done
        case .reference, .backrestLower, .done: return
        }
        scanner.aimedLandmark = aimedLandmark
        refreshOverlay()
    }

    /// Vuelve a empezar desde la referencia (por ejemplo, si el umbral se
    /// marcó mal).
    func restart() {
        phase = .reference(.sillRear)
        sillRear = nil
        sillFront = nil
        frame = nil
        backrestLower = nil
        lastCushion = nil
        lastBackrest = nil
        cushionCheck = nil
        backrestCheck = nil
        scanner.aimedLandmark = aimedLandmark
        refreshOverlay()
    }

    /// Guarda el asiento tal como está ahora como el nuevo ideal.
    func saveAsIdeal() {
        guard let lastCushion, let lastBackrest else {
            alert = AlertMessage(error: PositionError.incompleteMeasurement)
            return
        }
        let seat = SeatPosition(cushionFront: lastCushion, backrestLower: lastBackrest.lower, backrestUpper: lastBackrest.upper)
        do {
            profile = try updateSeat.execute(id: profileID, seat: seat)
            evaluateStored()
            alert = .seatUpdated
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

    private var aimedLandmark: SeatLandmark? {
        switch phase {
        case .reference(let landmark): return landmark
        case .cushion: return .cushionFront
        case .backrestLower: return .backrestLower
        case .backrestUpper: return .backrestUpper
        case .done: return nil
        }
    }

    private func evaluateLive() {
        guard let frame, let profile, let aim = smoother.value else { return }
        switch phase {
        case .cushion:
            let cushion = frame.local(aim)
            lastCushion = cushion
            cushionCheck = checkSeat.cushion(cushion, profile: profile)
        case .backrestUpper:
            guard let backrestLower else { return }
            let lower = frame.local(backrestLower)
            let upper = frame.local(aim)
            lastBackrest = (lower, upper)
            backrestCheck = checkSeat.backrest(lower: lower, upper: upper, profile: profile)
        case .reference, .backrestLower, .done:
            break
        }
    }

    /// Recalcula los resultados con las últimas medidas (tras cambiar el ideal).
    private func evaluateStored() {
        guard let profile else { return }
        if let lastCushion {
            cushionCheck = checkSeat.cushion(lastCushion, profile: profile)
        }
        if let lastBackrest {
            backrestCheck = checkSeat.backrest(lower: lastBackrest.lower, upper: lastBackrest.upper, profile: profile)
        }
    }

    private func refreshOverlay() {
        var overlay = AROverlay()
        if let sillRear {
            overlay.addMarker(sillRear, .reference)
        }
        if let sillRear, let sillFront {
            overlay.addMarker(sillFront, .reference)
            overlay.addSegment(sillRear, sillFront, .reference)
        }

        if let frame, let seat = profile?.seat {
            // El fantasma del asiento ideal.
            let targetCushion = frame.world(seat.cushionFront)
            overlay.addMarker(targetCushion, .target)
            overlay.addSegment(frame.world(seat.backrestLower), frame.world(seat.backrestUpper), .target)

            let aim = smoother.value
            switch phase {
            case .cushion:
                if let aim {
                    let style: AROverlay.Style = cushionCheck?.isMatch == true ? .match : .current
                    overlay.addMarker(aim, style)
                    overlay.addSegment(aim, targetCushion, style)
                }
            case .backrestLower, .backrestUpper, .done:
                if let backrestLower {
                    overlay.addMarker(backrestLower, .current)
                    if phase == .backrestUpper, let aim, let targetDirection = (seat.backrestUpper - seat.backrestLower).normalized {
                        let style: AROverlay.Style = backrestCheck?.isMatch == true ? .match : .current
                        let current = aim - backrestLower
                        let ideal = frame.worldDirection(targetDirection) * current.length
                        overlay.addSegment(backrestLower, aim, style)
                        overlay.addSegment(backrestLower, backrestLower + ideal, .target)
                        overlay.addArc(center: backrestLower, from: current, to: ideal, radius: 0.15, style: style)
                    }
                }
            case .reference:
                break
            }
        }
        scanner.show(overlay)
    }
}
