import Foundation

/// Textos de cada punto que se marca con la cámara trasera.
extension SeatLandmark {
    var title: String {
        switch self {
        case .sillRear: return "Umbral, extremo trasero"
        case .sillFront: return "Umbral, extremo delantero"
        case .cushionFront: return "Borde delantero del cojín"
        case .backrestLower: return "Respaldo, parte baja"
        case .backrestUpper: return "Respaldo, parte alta"
        }
    }

    var instruction: String {
        switch self {
        case .sillRear:
            return "Abre la puerta y apunta la mira al umbral, junto al pilar de atrás."
        case .sillFront:
            return "Ahora al otro extremo del umbral, junto al pilar de delante."
        case .cushionFront:
            return "Apunta al centro del borde delantero del cojín del asiento."
        case .backrestLower:
            return "Apunta al centro del respaldo, un palmo por encima del cojín."
        case .backrestUpper:
            return "Apunta al centro del respaldo, justo debajo del reposacabezas."
        }
    }
}
