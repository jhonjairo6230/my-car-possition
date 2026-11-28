import SwiftUI

/// Pantalla de comprobación: "¿está el auto como lo dejé?".
///
/// Muestra la cámara, el veredicto en vivo y las notas de la posición (lo
/// que la cámara no mide: espejos, volante…).
struct CheckScreen: View {
    @State private var viewModel: CheckViewModel
    let cameraPreview: CameraPreviewSource

    @State private var isConfirmingReference = false
    @State private var isEditingDetails = false

    init(viewModel: CheckViewModel, cameraPreview: CameraPreviewSource) {
        _viewModel = State(wrappedValue: viewModel)
        self.cameraPreview = cameraPreview
    }

    var body: some View {
        Group {
            if viewModel.isSupported {
                content
            } else {
                UnsupportedDeviceView()
            }
        }
        .navigationTitle(viewModel.profile?.name ?? "Comprobar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isConfirmingReference = true
                    } label: {
                        Label("Guardar posición actual como referencia", systemImage: "scope")
                    }
                    Button {
                        isEditingDetails = true
                    } label: {
                        Label("Editar nombre y notas", systemImage: "pencil")
                    }
                } label: {
                    Label("Más", systemImage: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "¿Guardar la posición actual como referencia?",
            isPresented: $isConfirmingReference,
            titleVisibility: .visible
        ) {
            Button("Guardar como referencia") { viewModel.saveCurrentAsReference() }
        } message: {
            Text("Hazlo solo si ahora estás sentado exactamente como te gusta.")
        }
        .sheet(isPresented: $isEditingDetails) {
            if let profile = viewModel.profile {
                ProfileDetailsForm(name: profile.name, notes: profile.notes) { name, notes in
                    viewModel.saveDetails(name: name, notes: notes)
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CameraPreview(source: cameraPreview)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topLeading) {
                        FaceStatusBadge(isFaceDetected: viewModel.isFaceDetected)
                            .padding(10)
                    }

                verdict

                if let notes = viewModel.profile?.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Revisa también", systemImage: "checklist")
                            .font(.headline)
                        Text(notes)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var verdict: some View {
        if let evaluation = viewModel.evaluation {
            if evaluation.isMatch {
                Label("Todo en su sitio", systemImage: "checkmark.seal.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ajusta esto").font(.title2.bold())
                    ForEach(Array(evaluation.adjustments.enumerated()), id: \.offset) { _, adjustment in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: adjustment.systemImage)
                                .font(.title)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(adjustment.title).font(.headline)
                                if let hint = adjustment.hint {
                                    Text(hint).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            offsets(evaluation)
        } else {
            HStack(spacing: 12) {
                ProgressView()
                Text("Mira hacia el móvil con las manos en el volante…")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    /// Las diferencias en bruto, para quien quiera los números.
    private func offsets(_ evaluation: PositionEvaluation) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                Text("Adelante/atrás")
                Text(Self.centimeters(evaluation.depthOffset))
            }
            GridRow {
                Text("Altura")
                Text(Self.centimeters(evaluation.heightOffset))
            }
            GridRow {
                Text("Lado")
                Text(Self.centimeters(evaluation.lateralOffset))
            }
            GridRow {
                Text("Ángulo del móvil")
                Text(String(format: "%.1f°", evaluation.phoneTiltChange))
            }
        }
        .font(.footnote.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private static func centimeters(_ meters: Double) -> String {
        String(format: "%+.1f cm", meters * 100)
    }
}

/// Hoja para cambiar el nombre y las notas de una posición.
private struct ProfileDetailsForm: View {
    @State var name: String
    @State var notes: String
    /// Devuelve `true` si se guardó; entonces la hoja se cierra.
    let onSave: (String, String) -> Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("Nombre", text: $name)
                Section("Notas") {
                    TextField("Volante, espejos, respaldo…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Editar posición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if onSave(name, notes) { dismiss() }
                    }
                }
            }
        }
    }
}
