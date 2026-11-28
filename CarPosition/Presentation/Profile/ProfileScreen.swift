import SwiftUI

/// Ficha de una posición: desde aquí se ajusta el asiento (cámara trasera) y,
/// como complemento, se comprueba con la cara (cámara frontal).
struct ProfileScreen: View {
    @State private var viewModel: ProfileViewModel
    @State private var isEditingDetails = false

    init(viewModel: ProfileViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                NavigationLink(value: AppRoute.seatCheck(viewModel.id)) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ajustar asiento").font(.headline)
                            Text("Cámara trasera: la guía dibuja la posición ideal sobre el asiento.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "arkit")
                    }
                }
                .accessibilityIdentifier("seatCheck")
            }

            Section {
                if viewModel.hasHeadReference {
                    NavigationLink(value: AppRoute.headCheck(viewModel.id)) {
                        headRow(title: "Comprobar con mi cara", detail: "Cámara frontal: dónde queda tu cabeza respecto al móvil en su soporte.")
                    }
                    .accessibilityIdentifier("headCheck")
                }
                NavigationLink(value: AppRoute.headCalibration(viewModel.id)) {
                    headRow(
                        title: viewModel.hasHeadReference ? "Volver a calibrar la cara" : "Calibrar con mi cara",
                        detail: "Siéntate en la posición ideal con el móvil en su soporte."
                    )
                }
                .accessibilityIdentifier("headCalibration")
            } header: {
                Text("Complemento")
            }

            if let profile = viewModel.profile {
                Section("Medidas guardadas") {
                    LabeledContent("Borde del cojín", value: String(format: "%.0f cm desde la pisadera", profile.seat.cushionFront.x * 100))
                    LabeledContent("Altura del cojín", value: String(format: "%.0f cm", profile.seat.cushionFront.y * 100))
                    LabeledContent("Respaldo", value: String(format: "%.0f°", profile.seat.backrestAngle))
                }
                if !profile.notes.isEmpty {
                    Section("Notas") {
                        Text(profile.notes)
                    }
                }
            }
        }
        .navigationTitle(viewModel.profile?.name ?? "Posición")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Editar") { isEditingDetails = true }
            }
        }
        .sheet(isPresented: $isEditingDetails) {
            if let profile = viewModel.profile {
                ProfileDetailsForm(name: profile.name, notes: profile.notes) { name, notes in
                    viewModel.saveDetails(name: name, notes: notes)
                }
            }
        }
        .onAppear { viewModel.load() }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    private func headRow(title: String, detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "faceid")
        }
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
                    TextField("Volante, espejos…", text: $notes, axis: .vertical)
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
