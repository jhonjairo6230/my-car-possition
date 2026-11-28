import Foundation

/// Cuánto se puede alejar una medición de la referencia sin que haga falta
/// ajustar nada.
///
/// Los valores por defecto salen de dos ideas: ARKit mide la cara con un
/// ruido de pocos milímetros, y los rieles de un asiento avanzan a saltos de
/// 1 a 1,5 cm. Pedir más precisión haría que nunca saliera "todo bien".
struct HeadTolerance: Equatable {
    /// Metros hacia delante o hacia atrás.
    var depth: Double
    /// Metros hacia arriba o hacia abajo.
    var height: Double
    /// Metros hacia los lados. Es más amplia: uno no se sienta siempre en el
    /// mismo centímetro del asiento, y no hay palanca para eso.
    var lateral: Double
    /// Grados que puede cambiar el ángulo del móvil en su soporte.
    var phoneTiltDegrees: Double

    static let standard = HeadTolerance(depth: 0.015, height: 0.015, lateral: 0.03, phoneTiltDegrees: 3)
}
