import Foundation

/// Los puntos que se marcan con la cámara trasera, en el orden en que se piden.
///
/// Los dos primeros son **del auto** (no se mueven nunca) y fijan el sistema
/// de referencia (``CarFrame``). Los otros tres son **del asiento**.
enum SeatLandmark: CaseIterable, Equatable, Hashable {
    /// Umbral de la puerta del conductor, en su extremo trasero (junto al pilar B).
    case sillRear
    /// Umbral de la puerta del conductor, en su extremo delantero (junto al pilar A).
    case sillFront
    /// Centro del borde delantero del cojín del asiento.
    case cushionFront
    /// Centro del respaldo, en su parte baja (un palmo sobre el cojín).
    case backrestLower
    /// Centro del respaldo, en su parte alta (justo bajo el reposacabezas).
    case backrestUpper

    /// `true` para los puntos del auto, que sirven de referencia.
    var isCarReference: Bool {
        self == .sillRear || self == .sillFront
    }

    /// El punto que se pide después de este, o `nil` si es el último.
    var next: SeatLandmark? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    /// El punto que se pidió antes de este, o `nil` si es el primero.
    var previous: SeatLandmark? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return nil }
        return all[index - 1]
    }
}
