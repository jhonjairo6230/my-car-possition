import Foundation

/// Errores de negocio que la interfaz sabe mostrar al usuario.
///
/// La capa Data traduce sus errores técnicos (SwiftData) a estos casos.
enum PositionError: Error, Equatable {
    /// No se pudo leer o escribir en la base de datos local.
    case storageFailed
    /// La posición ya no existe (por ejemplo, se eliminó).
    case profileNotFound
    /// El nombre está vacío.
    case invalidName
    /// Se acabó el tiempo sin ver la cara el tiempo suficiente.
    case faceNotFound
    /// No hay lecturas suficientes para guardar una referencia.
    case notEnoughSamples
    /// La mira no está sobre ninguna superficie reconocida.
    case noSurface
    /// Los dos puntos del umbral están demasiado juntos.
    case referenceTooShort
    /// La línea entre los dos puntos del umbral está muy inclinada.
    case referenceNotHorizontal
    /// Faltan puntos por marcar.
    case incompleteMeasurement
}

extension PositionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .storageFailed:
            return "No se pudieron guardar o recuperar tus posiciones."
        case .profileNotFound:
            return "Esa posición ya no existe."
        case .invalidName:
            return "Ponle un nombre a la posición."
        case .faceNotFound:
            return "No se vio tu cara el tiempo suficiente. Mira hacia el móvil, con buena luz, e inténtalo otra vez."
        case .notEnoughSamples:
            return "Aún no hay una medición estable. Mira hacia el móvil un par de segundos."
        case .noSurface:
            return "La mira no está sobre ninguna superficie. Acércate un poco, mueve el móvil despacio y vuelve a apuntar."
        case .referenceTooShort:
            return "Los dos puntos del umbral están muy juntos. Marca uno junto al pilar trasero y otro junto al delantero."
        case .referenceNotHorizontal:
            return "Esos dos puntos no parecen del umbral. Marca los dos extremos del umbral de la puerta, a la misma altura."
        case .incompleteMeasurement:
            return "Faltan puntos por marcar."
        }
    }
}
