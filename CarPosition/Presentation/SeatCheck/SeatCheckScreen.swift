import SwiftUI

/// Guía del asiento con realidad aumentada: dibuja la posición ideal sobre el
/// asiento real y dice qué ajustar mientras se mueven las palancas.
struct SeatCheckScreen: View {
    @State private var viewModel: SeatCheckViewModel
    let preview: CameraPreviewSource

    @State private var isConfirmingIdeal = false
    @State private var isShowingSillHelp = false

    init(viewModel: SeatCheckViewModel, preview: CameraPreviewSource) {
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
        .navigationTitle(viewModel.profile?.name ?? "Ajustar asiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reiniciar") { viewModel.restart() }
            }
        }
        .confirmationDialog(
            "¿Guardar el asiento actual como ideal?",
            isPresented: $isConfirmingIdeal,
            titleVisibility: .visible
        ) {
            Button("Guardar como ideal") { viewModel.saveAsIdeal() }
        } message: {
            Text("La próxima vez la guía buscará esta posición.")
        }
        .sheet(isPresented: $isShowingSillHelp) {
            SillHelpView()
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .alert(item: $viewModel.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }

    @ViewBuilder
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch viewModel.phase {
            case .reference(let landmark):
                Text("Referencia · \(landmark.title)").font(.headline)
                Text(landmark.instruction).font(.subheadline)
                sillHelpButton
            case .cushion:
                Text("Adelante/atrás y altura").font(.headline)
                Text("Apunta al borde delantero del cojín y mueve el asiento hasta que la bola naranja toque la verde.")
                    .font(.subheadline)
            case .backrestLower:
                Text("Respaldo · parte baja").font(.headline)
                Text(SeatLandmark.backrestLower.instruction).font(.subheadline)
            case .backrestUpper:
                Text("Respaldo · ángulo").font(.headline)
                Text("Apunta a la parte alta del respaldo y muévelo hasta que la barra naranja cubra la verde.")
                    .font(.subheadline)
            case .done:
                Text("Resumen").font(.headline)
            }
            if !viewModel.isTrackingReady {
                Text("Mueve el móvil despacio para que reconozca el auto…")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    /// Abre la explicación de la pisadera (dónde están los dos puntos).
    private var sillHelpButton: some View {
        Button {
            isShowingSillHelp = true
        } label: {
            Label("¿Qué es la pisadera?", systemImage: "questionmark.circle")
                .font(.footnote.weight(.semibold))
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch viewModel.phase {
            case .reference, .backrestLower:
                markButton
            case .cushion:
                CushionResult(check: viewModel.cushionCheck)
                nextButton("Siguiente: respaldo")
            case .backrestUpper:
                BackrestResult(check: viewModel.backrestCheck)
                nextButton("Terminar")
            case .done:
                CushionResult(check: viewModel.cushionCheck)
                BackrestResult(check: viewModel.backrestCheck)
                if let notes = viewModel.profile?.notes, !notes.isEmpty {
                    Label(notes, systemImage: "checklist")
                        .font(.footnote)
                }
                if viewModel.canSaveAsIdeal {
                    Button("Guardar este asiento como ideal") { isConfirmingIdeal = true }
                        .font(.footnote)
                }
            }
        }
    }

    private var markButton: some View {
        HStack {
            Spacer()
            Button {
                viewModel.mark()
            } label: {
                Label("Marcar", systemImage: "scope").padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isAiming)
        }
    }

    private func nextButton(_ title: String) -> some View {
        HStack {
            Spacer()
            Button(title) { viewModel.next() }
                .buttonStyle(.bordered)
        }
    }
}

/// Resultado del cojín: "En su sitio" o la lista de ajustes.
private struct CushionResult: View {
    let check: CushionCheck?

    var body: some View {
        if let check {
            if check.isMatch {
                MatchLabel(text: "Cojín en su sitio")
            } else {
                AdjustmentList(adjustments: check.adjustments)
            }
        } else {
            Text("Apunta al borde del cojín…").foregroundStyle(.secondary)
        }
    }
}

/// Resultado del respaldo: ángulo actual e ideal, y qué hacer.
private struct BackrestResult: View {
    let check: BackrestCheck?

    var body: some View {
        if let check {
            VStack(alignment: .leading, spacing: 6) {
                if let adjustment = check.adjustment {
                    AdjustmentList(adjustments: [adjustment])
                } else {
                    MatchLabel(text: "Respaldo en su sitio")
                }
                Text("Ahora \(check.currentAngle, specifier: "%.0f")° · ideal \(check.targetAngle, specifier: "%.0f")°")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Apunta a la parte alta del respaldo…").foregroundStyle(.secondary)
        }
    }
}

private struct MatchLabel: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.seal.fill")
            .font(.headline)
            .foregroundStyle(.green)
    }
}

/// Lista de ajustes con su icono.
struct AdjustmentList: View {
    let adjustments: [Adjustment]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(adjustments.enumerated()), id: \.offset) { _, adjustment in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: adjustment.systemImage)
                        .font(.title2)
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
    }
}
