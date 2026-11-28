import SwiftUI
import UIKit

/// Calibrar con la **cámara frontal**: guarda dónde queda la cabeza respecto
/// al móvil en su soporte, como complemento de la posición.
struct HeadCalibrationScreen: View {
    @State private var viewModel: HeadCalibrationViewModel
    let cameraPreview: CameraPreviewSource

    @Environment(\.dismiss) private var dismiss

    init(viewModel: HeadCalibrationViewModel, cameraPreview: CameraPreviewSource) {
        // `State(wrappedValue:)` guarda el ViewModel la primera vez: si SwiftUI
        // vuelve a crear esta vista, se conserva el mismo.
        _viewModel = State(wrappedValue: viewModel)
        self.cameraPreview = cameraPreview
    }

    var body: some View {
        Group {
            if viewModel.isSupported {
                content
            } else {
                UnsupportedDeviceView(camera: .front)
            }
        }
        .navigationTitle("Calibrar con mi cara")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: viewModel.phase) { _, phase in
            if case .saved = phase { dismiss() }
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack {
                    CameraPreview(source: cameraPreview)
                    overlay
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    FaceStatusBadge(
                        isFaceDetected: viewModel.isFaceDetected,
                        distanceCentimeters: viewModel.distanceCentimeters
                    )
                    .padding(10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Cómo calibrar").font(.headline)
                    Text("1. Deja el asiento en tu posición ideal (usa antes la guía con la cámara trasera).")
                    Text("2. Pon el móvil en su soporte, siempre en el mismo sitio y ángulo.")
                    Text("3. Pulsa Calibrar, pon las manos en el volante y mira al frente unos segundos.")
                }
                .font(.subheadline)


                actionButton
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var overlay: some View {
        switch viewModel.phase {
        case .countdown(let secondsLeft):
            Text("\(secondsLeft)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 8)
        case .capturing(let progress):
            VStack {
                Spacer()
                ProgressView(value: progress)
                    .tint(.green)
                    .padding()
            }
        case .ready, .saved:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.phase {
        case .ready, .saved:
            Button {
                hideKeyboard()
                viewModel.startCapture()
            } label: {
                Label("Calibrar", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canStart)
        case .countdown, .capturing:
            Button(role: .cancel) {
                viewModel.cancelCapture()
            } label: {
                Text(statusText).frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var statusText: String {
        if case .countdown = viewModel.phase {
            return "Prepárate… (tocar para cancelar)"
        }
        return "Midiendo, no te muevas… (tocar para cancelar)"
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
