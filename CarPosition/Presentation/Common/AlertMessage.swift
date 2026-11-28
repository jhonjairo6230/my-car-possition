import Foundation

/// Mensaje que la vista muestra en una alerta.
struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    /// Convierte cualquier error en un mensaje legible.
    /// Los ``PositionError`` traen su propio texto en español.
    init(error: Error) {
        self.init(
            title: "Algo salió mal",
            message: (error as? LocalizedError)?.errorDescription ?? "Ocurrió un error inesperado."
        )
    }

    static let referenceUpdated = AlertMessage(
        title: "Referencia guardada",
        message: "A partir de ahora se compara con la posición en la que estás sentado."
    )
}

extension AlertMessage: Equatable {
    /// Dos mensajes son iguales si dicen lo mismo (el `id` no cuenta).
    static func == (lhs: AlertMessage, rhs: AlertMessage) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }
}
