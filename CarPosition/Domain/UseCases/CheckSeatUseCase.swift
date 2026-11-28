import Foundation

/// Compara el asiento actual con el de una posición guardada, por partes.
struct CheckSeatUseCase {
    private let evaluator: SeatEvaluator

    init(tolerance: SeatTolerance = .standard) {
        evaluator = SeatEvaluator(tolerance: tolerance)
    }

    /// - Parameter cushionFront: borde delantero del cojín, en coordenadas del auto.
    func cushion(_ cushionFront: Vector3, profile: DrivingProfile) -> CushionCheck {
        evaluator.cushion(current: cushionFront, target: profile.seat.cushionFront)
    }

    /// - Parameters: puntos del respaldo, en coordenadas del auto.
    func backrest(lower: Vector3, upper: Vector3, profile: DrivingProfile) -> BackrestCheck {
        evaluator.backrest(
            currentAngle: SeatPosition.backrestAngle(lower: lower, upper: upper),
            targetAngle: profile.seat.backrestAngle
        )
    }
}
