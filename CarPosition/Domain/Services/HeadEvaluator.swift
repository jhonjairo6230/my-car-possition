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
struct HeadEvaluator {
    var tolerance: HeadTolerance = .standard

    func evaluate(current: PostureMeasurement, reference: PostureMeasurement) -> HeadEvaluation {
        let depthOffset = current.depth - reference.depth
        let heightOffset = current.height - reference.height
        let lateralOffset = current.lateral - reference.lateral
        let tilt = current.deviceGravity.angle(to: reference.deviceGravity)

        var adjustments: [Adjustment] = []
        if tilt > tolerance.phoneTiltDegrees {
            adjustments = [.realignPhone(degrees: Int(tilt.rounded()))]
        } else {
            if depthOffset > tolerance.depth {
                adjustments.append(.moveSeatForward(centimeters: Adjustment.centimeters(depthOffset)))
            } else if depthOffset < -tolerance.depth {
                adjustments.append(.moveSeatBackward(centimeters: Adjustment.centimeters(depthOffset)))
            }
            if heightOffset > tolerance.height {
                adjustments.append(.lowerSeat(centimeters: Adjustment.centimeters(heightOffset)))
            } else if heightOffset < -tolerance.height {
                adjustments.append(.raiseSeat(centimeters: Adjustment.centimeters(heightOffset)))
            }
            if lateralOffset > tolerance.lateral {
                adjustments.append(.shiftLeft(centimeters: Adjustment.centimeters(lateralOffset)))
            } else if lateralOffset < -tolerance.lateral {
                adjustments.append(.shiftRight(centimeters: Adjustment.centimeters(lateralOffset)))
            }
        }

        return HeadEvaluation(
            depthOffset: depthOffset,
            heightOffset: heightOffset,
            lateralOffset: lateralOffset,
            phoneTiltChange: tilt,
            adjustments: adjustments
        )
    }
}
