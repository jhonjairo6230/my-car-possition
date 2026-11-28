import SwiftUI

/// Explica qué es la pisadera y dónde están sus dos extremos, con un dibujo
/// de la puerta del conductor vista desde fuera.
///
/// Se abre con el botón "?" de las pantallas de realidad aumentada mientras se
/// marca la referencia.
struct SillHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DoorDiagram()
                        .frame(height: 220)
                        .accessibilityLabel("Dibujo de la puerta del conductor abierta con la pisadera abajo, el pilar A a la izquierda y el pilar B a la derecha")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Qué es la pisadera?").font(.headline)
                        Text("Es la parte de abajo del marco de la puerta del conductor: la franja que pisas o sobre la que pasas el pie al subir al auto. Suele tener una placa de plástico o metal. También se le dice estribo o umbral.")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Los dos puntos").font(.headline)
                        Label("**Extremo trasero:** donde termina la pisadera junto al **pilar B**, el poste entre tu puerta y la de atrás.", systemImage: "1.circle.fill")
                        Label("**Extremo delantero:** el otro final, junto al **pilar A**: el lado de las bisagras, hacia el parabrisas.", systemImage: "2.circle.fill")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Para que mida bien").font(.headline)
                        Text("• Marca siempre los mismos dos sitios, por ejemplo un tornillo o el borde de la placa.")
                        Text("• Si la alfombrilla tapa la pisadera, apunta al plástico, no a la alfombrilla.")
                        Text("• Mueve el móvil despacio hasta que la mira se ponga verde y pulsa Marcar.")
                    }
                }
                .padding()
            }
            .navigationTitle("La pisadera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Entendido") { dismiss() }
                }
            }
        }
    }
}

/// La puerta del conductor abierta, vista desde fuera: el hueco de la
/// puerta, los pilares A y B y la pisadera abajo con sus dos puntos.
private struct DoorDiagram: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let left = width * 0.12
            let right = width * 0.88
            let top = height * 0.12
            let bottom = height * 0.72

            ZStack {
                // Hueco de la puerta (con el techo inclinado hacia el parabrisas).
                Path { path in
                    path.move(to: CGPoint(x: left, y: bottom))
                    path.addLine(to: CGPoint(x: left + width * 0.12, y: top))
                    path.addLine(to: CGPoint(x: right, y: top))
                    path.addLine(to: CGPoint(x: right, y: bottom))
                }
                .stroke(Color.secondary, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))

                // Pisadera.
                Path { path in
                    path.move(to: CGPoint(x: left, y: bottom))
                    path.addLine(to: CGPoint(x: right, y: bottom))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))

                point(number: 2, at: CGPoint(x: left + 10, y: bottom))
                point(number: 1, at: CGPoint(x: right - 10, y: bottom))

                Text("Pilar A")
                    .font(.caption.bold())
                    .position(x: left + width * 0.02, y: top + (bottom - top) * 0.35)
                Text("Pilar B")
                    .font(.caption.bold())
                    .position(x: right - width * 0.08, y: top + (bottom - top) * 0.35)
                Text("Pisadera")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .position(x: width / 2, y: bottom + 26)
                Text("◀ parabrisas")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: left + width * 0.08, y: height - 8)
            }
        }
    }

    private func point(number: Int, at position: CGPoint) -> some View {
        Text("\(number)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color.orange))
            .position(position)
    }
}
