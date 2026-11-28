import Foundation

/// Compara una medición con la referencia y decide qué ajustar.
///
/// Reglas:
///
/// 1. Si el móvil cambió de ángulo más de lo tolerado, **solo** se pide
///    recolocarlo: con el móvil girado, todas las distancias salen movidas
///    (3° a 60 cm son 3 cm) y los demás consejos serían falsos.
/// 2. Si no, cada eje fuera de tolerancia produce un ajuste, en el orden en
///    que conviene hacerlos: primero adelante/atrás, luego altura, luego lado.
struct PositionEvaluator {
    var tolerance: Tolerance = .standard

    func evaluate(current: PostureMeasurement, reference: PostureMeasurement) -> PositionEvaluation {
        let depthOffset = current.depth - reference.depth
        let heightOffset = current.height - reference.height
        let lateralOffset = current.lateral - reference.lateral
        let tilt = current.deviceGravity.angle(to: reference.deviceGravity)

        var adjustments: [Adjustment] = []
        if tilt > tolerance.phoneTiltDegrees {
            adjustments = [.realignPhone(degrees: Int(tilt.rounded()))]
        } else {
            if depthOffset > tolerance.depth {
                adjustments.append(.moveSeatForward(centimeters: Self.centimeters(depthOffset)))
            } else if depthOffset < -tolerance.depth {
                adjustments.append(.moveSeatBackward(centimeters: Self.centimeters(depthOffset)))
            }
            if heightOffset > tolerance.height {
                adjustments.append(.lowerSeat(centimeters: Self.centimeters(heightOffset)))
            } else if heightOffset < -tolerance.height {
                adjustments.append(.raiseSeat(centimeters: Self.centimeters(heightOffset)))
            }
            if lateralOffset > tolerance.lateral {
                adjustments.append(.shiftLeft(centimeters: Self.centimeters(lateralOffset)))
            } else if lateralOffset < -tolerance.lateral {
                adjustments.append(.shiftRight(centimeters: Self.centimeters(lateralOffset)))
            }
        }

        return PositionEvaluation(
            depthOffset: depthOffset,
            heightOffset: heightOffset,
            lateralOffset: lateralOffset,
            phoneTiltChange: tilt,
            adjustments: adjustments
        )
    }

    /// Metros → centímetros enteros, al menos 1.
    static func centimeters(_ meters: Double) -> Int {
        max(1, Int((abs(meters) * 100).rounded()))
    }
}
