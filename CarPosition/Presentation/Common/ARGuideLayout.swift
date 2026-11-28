import SwiftUI

/// Distribución común de las pantallas de realidad aumentada: la cámara a
/// pantalla completa, la mira en el centro, un panel arriba con la
/// instrucción y otro abajo con el resultado y los botones.
struct ARGuideLayout<Top: View, Bottom: View>: View {
    let preview: CameraPreviewSource
    let isAiming: Bool
    @ViewBuilder let top: () -> Top
    @ViewBuilder let bottom: () -> Bottom

    var body: some View {
        ZStack {
            CameraPreview(source: preview)
                .ignoresSafeArea()
            Crosshair(isAiming: isAiming)
                .allowsHitTesting(false)
            VStack(spacing: 0) {
                top()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                Spacer()
                bottom()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding()
            }
        }
    }
}

/// La mira del centro: verde si hay una superficie debajo, blanca si no.
struct Crosshair: View {
    let isAiming: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 36, height: 36)
            Rectangle().frame(width: 2, height: 14)
            Rectangle().frame(width: 14, height: 2)
        }
        .foregroundStyle(isAiming ? Color.green : Color.white)
        .shadow(color: .black.opacity(0.6), radius: 2)
        .accessibilityLabel(isAiming ? "Mira sobre una superficie" : "Mira sin superficie")
    }
}
