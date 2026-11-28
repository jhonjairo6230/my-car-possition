import SwiftUI

/// Lo que se ve si el dispositivo no puede seguir caras con ARKit.
struct UnsupportedDeviceView: View {
    var body: some View {
        ContentUnavailableView(
            "Este dispositivo no puede medir",
            systemImage: "faceid",
            description: Text("Hace falta un iPhone con seguimiento facial de ARKit (iPhone XS, XR o posterior). En el simulador no funciona.")
        )
    }
}
