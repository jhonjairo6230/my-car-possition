import Foundation

/// Dice qué ajustar para volver a la posición guardada.
struct EvaluatePositionUseCase {
    private let evaluator: PositionEvaluator

    init(tolerance: Tolerance = .standard) {
        evaluator = PositionEvaluator(tolerance: tolerance)
    }

    func execute(current: PostureMeasurement, profile: DrivingProfile) -> PositionEvaluation {
        evaluator.evaluate(current: current, reference: profile.reference)
    }
}
