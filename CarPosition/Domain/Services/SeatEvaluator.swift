import Foundation

/// Resultado de comparar el borde delantero del cojín con el guardado.
struct CushionCheck: Equatable {
    /// Metros. Positivo: el cojín está **más adelante** que el guardado.
    var forwardOffset: Double
    /// Metros. Positivo: el cojín está **más alto**.
    var heightOffset: Double
    /// Qué ajustar (adelante/atrás primero, luego altura). Vacía si coincide.
    var adjustments: [Adjustment]

    var isMatch: Bool { adjustments.isEmpty }
}

/// Resultado de comparar el ángulo del respaldo con el guardado.
struct BackrestCheck: Equatable {
    var currentAngle: Double
    var targetAngle: Double
    /// Qué ajustar, o `nil` si coincide.
    var adjustment: Adjustment?

    /// Grados. Positivo: el respaldo está **más inclinado** que el guardado.
    var angleOffset: Double { currentAngle - targetAngle }
    var isMatch: Bool { adjustment == nil }
}

/// Compara el asiento actual con el guardado, por partes: primero el cojín
/// (adelante/atrás y altura) y luego el respaldo. Van por separado porque la
/// guía en realidad aumentada los mide uno detrás de otro.
struct SeatEvaluator {
    var tolerance: SeatTolerance = .standard

    /// - Parameters:
    ///   - current: borde delantero del cojín ahora, en coordenadas del auto.
    ///   - target: el guardado.
    func cushion(current: Vector3, target: Vector3) -> CushionCheck {
        let forwardOffset = current.x - target.x
        let heightOffset = current.y - target.y
        var adjustments: [Adjustment] = []
        if forwardOffset > tolerance.forward {
            adjustments.append(.moveSeatBackward(centimeters: Adjustment.centimeters(forwardOffset)))
        } else if forwardOffset < -tolerance.forward {
            adjustments.append(.moveSeatForward(centimeters: Adjustment.centimeters(forwardOffset)))
        }
        if heightOffset > tolerance.height {
            adjustments.append(.lowerSeat(centimeters: Adjustment.centimeters(heightOffset)))
        } else if heightOffset < -tolerance.height {
            adjustments.append(.raiseSeat(centimeters: Adjustment.centimeters(heightOffset)))
        }
        return CushionCheck(forwardOffset: forwardOffset, heightOffset: heightOffset, adjustments: adjustments)
    }

    func backrest(currentAngle: Double, targetAngle: Double) -> BackrestCheck {
        let offset = currentAngle - targetAngle
        var adjustment: Adjustment?
        if offset > tolerance.backrestDegrees {
            adjustment = .straightenBackrest(degrees: Adjustment.degrees(offset))
        } else if offset < -tolerance.backrestDegrees {
            adjustment = .reclineBackrest(degrees: Adjustment.degrees(offset))
        }
        return BackrestCheck(currentAngle: currentAngle, targetAngle: targetAngle, adjustment: adjustment)
    }
}
