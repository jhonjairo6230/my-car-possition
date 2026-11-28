import Foundation

/// Una posición de manejo guardada: la referencia con la que se compara.
///
/// En la interfaz se llama **posición** ("Mi posición", "Viaje largo"…).
/// Guarda:
///
/// - `seat`: el asiento medido con la **cámara trasera** (siempre).
/// - `head`: dónde queda la cabeza respecto al móvil en su soporte, medido con
///   la **cámara frontal**. Es opcional: un complemento que se calibra aparte.
/// - `notes`: lo que no se mide (espejos, volante).
struct DrivingProfile: Identifiable, Equatable {
    let id: UUID
    var name: String
    var notes: String
    var seat: SeatPosition
    var head: PostureMeasurement?
    let createdAt: Date
    /// Última vez que se guardó una medición.
    var updatedAt: Date
}
