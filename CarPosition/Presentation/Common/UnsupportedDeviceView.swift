import SwiftUI

/// Lo que se ve si el dispositivo no puede usar la cámara que hace falta.
struct UnsupportedDeviceView: View {
    enum Camera {
        /// Cámara trasera con seguimiento del mundo (guía del asiento).
        case rear
        /// Cámara frontal con seguimiento facial (comprobación con la cara).
        case front
    }

    let camera: Camera

    var body: some View {
        ContentUnavailableView(
            "Este dispositivo no puede medir",
            systemImage: camera == .rear ? "arkit" : "faceid",
            description: Text(description)
        )
    }

    private var description: String {
        switch camera {
        case .rear:
            return "Hace falta un iPhone con realidad aumentada (ARKit). En el simulador no funciona."
        case .front:
            return "Hace falta un iPhone con seguimiento facial de ARKit (iPhone XS, XR o posterior). En el simulador no funciona."
        }
    }
}
