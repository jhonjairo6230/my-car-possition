import Foundation

/// Dice qué ajustar para que la cabeza vuelva a quedar donde se guardó.
struct EvaluateHeadUseCase {
    private let evaluator: HeadEvaluator

    init(tolerance: HeadTolerance = .standard) {
        evaluator = HeadEvaluator(tolerance: tolerance)
    }

    /// - Returns: `nil` si la posición aún no tiene referencia de la cabeza.
    func execute(current: PostureMeasurement, profile: DrivingProfile) -> HeadEvaluation? {
        guard let reference = profile.head else { return nil }
        return evaluator.evaluate(current: current, reference: reference)
    }
}
