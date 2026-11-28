import SwiftUI

/// Guardar una posición nueva marcando el asiento con la cámara trasera.
struct SeatCalibrationScreen: View {
    @State private var viewModel: SeatCalibrationViewModel
    let preview: CameraPreviewSource

    @Environment(\.dismiss) private var dismiss

    init(viewModel: SeatCalibrationViewModel, preview: CameraPreviewSource) {
        // `State(wrappedValue:)` conserva el primer ViewModel aunque SwiftUI
        // vuelva a crear esta vista.
        _viewModel = State(wrappedValue: viewModel)
        self.preview = preview
    }

    var body: some View {
        Group {
            if viewModel.isSupported {
                ARGuideLayout(preview: preview, isAiming: viewModel.isAiming) {
                    instructions
                } bottom: {
                    controls
                }
            } else {
                UnsupportedDeviceView(camera: .rear)
            }
        }
        .navigationTitle("Nueva posición")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: viewModel.step) { _, step in
            if case .saved = step { dismiss() }
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    @ViewBuilder
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch viewModel.step {
            case .marking(let landmark):
                Text("Punto \(viewModel.markedCount + 1) de \(SeatLandmark.allCases.count) · \(landmark.title)")
                    .font(.headline)
                Text(landmark.instruction)
                    .font(.subheadline)
            case .naming, .saved:
                Text("Asiento medido").font(.headline)
                if let angle = viewModel.backrestAngle {
                    Text("Respaldo a \(angle, specifier: "%.0f")° de la vertical.")
                        .font(.subheadline)
                }
            }
            if !viewModel.isTrackingReady {
                Text("Mueve el móvil despacio para que reconozca el auto…")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch viewModel.step {
        case .marking:
            HStack {
                Button("Deshacer") { viewModel.undo() }
                    .disabled(!viewModel.canUndo)
                Spacer()
                Button {
                    viewModel.mark()
                } label: {
                    Label("Marcar", systemImage: "scope")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isAiming)
            }
        case .naming, .saved:
            VStack(alignment: .leading, spacing: 10) {
                TextField("Nombre", text: $viewModel.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("profileName")
                TextField("Notas: volante, espejos…", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("profileNotes")
                HStack {
                    Button("Deshacer") { viewModel.undo() }
                    Spacer()
                    Button("Guardar posición") { viewModel.save() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
