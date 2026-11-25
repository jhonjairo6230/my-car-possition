import Foundation

/// Una posición de manejo guardada: la referencia con la que se compara.
///
/// En la interfaz se llama **posición** ("Mi posición", "Posición de
/// lluvia"…). Guarda la medición de la calibración y unas notas libres para
/// lo que la cámara no puede medir (espejos, volante, respaldo).
struct DrivingProfile: Identifiable, Equatable {
    let id: UUID
    var name: String
    /// Recordatorios del conductor: "Volante: 2ª muesca", "Espejo izquierdo:
    /// ver la manija de la puerta"…
    var notes: String
    var reference: PostureMeasurement
    let createdAt: Date
    /// Última vez que se guardó una nueva referencia.
    var updatedAt: Date
}
