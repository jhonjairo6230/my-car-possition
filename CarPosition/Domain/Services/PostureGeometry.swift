import Foundation

/// Convierte lo que ve ARKit (dónde está la cámara, hacia dónde mira y dónde
/// está la cabeza) en una ``PostureSample``.
///
/// Las cuentas se hacen en el "mundo" de ARKit alineado con la gravedad
/// (`y` hacia arriba). Así el resultado **no depende de cómo esté puesto el
/// móvil** (vertical, horizontal o algo inclinado): la altura siempre es
/// vertical de verdad y la profundidad siempre es horizontal.
///
/// Vive en el dominio, sin ARKit, para poder probar la geometría con
/// números ([ADR 0007](../../../docs/adr/0007-arkit-seguimiento-facial.md)).
enum PostureGeometry {
    /// - Parameters:
    ///   - cameraPosition: posición de la cámara en el mundo.
    ///   - cameraRight: eje `x` de la cámara en el mundo (columna 0 de su
    ///     transformación).
    ///   - cameraUp: eje `y` de la cámara (columna 1).
    ///   - cameraBack: eje `z` de la cámara (columna 2). La cámara mira hacia
    ///     `-cameraBack`.
    ///   - headPosition: centro de la cara en el mundo.
    static func sample(
        cameraPosition: Vector3,
        cameraRight: Vector3,
        cameraUp: Vector3,
        cameraBack: Vector3,
        headPosition: Vector3
    ) -> PostureSample {
        let toHead = headPosition - cameraPosition
        let horizontal = toHead.horizontal

        // Dirección horizontal "de la cámara hacia el conductor". Se usa el eje
        // óptico (fijo con el móvil), no la dirección a la cabeza: si se usara
        // la cabeza, un desplazamiento lateral nunca se notaría.
        var towardDriver = (-cameraBack).horizontal.normalized
            ?? horizontal.normalized   // Móvil mirando al techo: caso raro.
            ?? Vector3(0, 0, 1)
        if horizontal.dot(towardDriver) < 0 {
            towardDriver = -towardDriver
        }

        // El conductor mira hacia la cámara (-towardDriver); su derecha es
        // mirada × arriba.
        let driverRight = (-towardDriver).cross(.up)

        // La gravedad (0, -1, 0) del mundo expresada en los ejes del móvil.
        let gravity = Vector3(-cameraRight.y, -cameraUp.y, -cameraBack.y)

        return PostureSample(
            depth: horizontal.dot(towardDriver),
            height: toHead.y,
            lateral: horizontal.dot(driverRight),
            deviceGravity: gravity
        )
    }
}
