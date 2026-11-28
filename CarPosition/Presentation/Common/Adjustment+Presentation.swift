import Foundation

/// Textos e iconos de cada ajuste. Viven en presentación: el dominio no sabe
/// de idiomas ni de SF Symbols.
extension Adjustment {
    var title: String {
        switch self {
        case .realignPhone(let degrees):
            return "Recoloca el móvil en su soporte (se giró \(degrees)°)"
        case .moveSeatForward(let cm):
            return "Adelanta el asiento unos \(cm) cm"
        case .moveSeatBackward(let cm):
            return "Atrasa el asiento unos \(cm) cm"
        case .raiseSeat(let cm):
            return "Sube el asiento unos \(cm) cm"
        case .lowerSeat(let cm):
            return "Baja el asiento unos \(cm) cm"
        case .shiftLeft(let cm):
            return "Siéntate unos \(cm) cm más a tu izquierda"
        case .shiftRight(let cm):
            return "Siéntate unos \(cm) cm más a tu derecha"
        case .reclineBackrest(let degrees):
            return "Inclina el respaldo unos \(degrees)° hacia atrás"
        case .straightenBackrest(let degrees):
            return "Endereza el respaldo unos \(degrees)°"
        }
    }

    /// Una pista de qué más puede causar la diferencia.
    var hint: String? {
        switch self {
        case .realignPhone:
            return "Las medidas son relativas al móvil: si su ángulo cambia, todo sale movido."
        case .moveSeatForward:
            return "O endereza un poco el respaldo."
        case .moveSeatBackward:
            return "O inclina un poco el respaldo hacia atrás."
        case .raiseSeat, .lowerSeat:
            return "Si el asiento no tiene altura, revisa la inclinación del respaldo."
        case .shiftLeft, .shiftRight, .reclineBackrest, .straightenBackrest:
            return nil
        }
    }

    var systemImage: String {
        switch self {
        case .realignPhone: return "iphone.gen3"
        case .moveSeatForward: return "arrow.up.circle.fill"
        case .moveSeatBackward: return "arrow.down.circle.fill"
        case .raiseSeat: return "arrow.up.to.line.circle.fill"
        case .lowerSeat: return "arrow.down.to.line.circle.fill"
        case .shiftLeft: return "arrow.left.circle.fill"
        case .shiftRight: return "arrow.right.circle.fill"
        case .reclineBackrest: return "arrow.counterclockwise.circle.fill"
        case .straightenBackrest: return "arrow.clockwise.circle.fill"
        }
    }
}
