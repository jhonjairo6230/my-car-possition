import Foundation

/// Textos de cada punto que se marca con la cámara trasera.
///
/// El "umbral" del código (`sillRear`, `sillFront`) en la interfaz se llama
/// **pisadera**: la parte de abajo del marco de la puerta, que es como se
/// conoce en Colombia y se entiende sin explicación.
extension SeatLandmark {
    var title: String {
        switch self {
        case .sillRear: return "Pisadera, extremo trasero"
        case .sillFront: return "Pisadera, extremo delantero"
        case .cushionFront: return "Borde delantero del cojín"
        case .backrestLower: return "Respaldo, parte baja"
        case .backrestUpper: return "Respaldo, parte alta"
        }
    }

    var instruction: String {
        switch self {
        case .sillRear:
            return "Abre la puerta del conductor. Apunta a la pisadera (la parte de abajo del marco de la puerta), en el extremo junto al pilar B: el poste entre tu puerta y la de atrás."
        case .sillFront:
            return "Ahora al otro extremo de la pisadera, junto al pilar A: el lado de las bisagras de la puerta, hacia el parabrisas."
        case .cushionFront:
            return "Apunta al centro del borde delantero del cojín del asiento."
        case .backrestLower:
            return "Apunta al centro del respaldo, un palmo por encima del cojín."
        case .backrestUpper:
            return "Apunta al centro del respaldo, justo debajo del reposacabezas."
        }
    }
}
