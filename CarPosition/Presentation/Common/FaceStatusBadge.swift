import SwiftUI

/// Píldora sobre la cámara: si se ve la cara y, si se sabe, a qué distancia.
struct FaceStatusBadge: View {
    let isFaceDetected: Bool
    var distanceCentimeters: Int?

    var body: some View {
        Label(text, systemImage: isFaceDetected ? "face.smiling" : "eye.slash")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(isFaceDetected ? Color.green : Color.orange)
            .accessibilityIdentifier("faceStatus")
    }

    private var text: String {
        guard isFaceDetected else { return "Buscando tu cara…" }
        if let distanceCentimeters {
            return "Cara detectada · \(distanceCentimeters) cm"
        }
        return "Cara detectada"
    }
}
