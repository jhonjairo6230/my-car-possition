import SwiftUI

/// Pantalla principal: las posiciones guardadas.
///
/// Tocar una posición abre la comprobación; el botón "+" abre la
/// calibración de una nueva. Las pantallas siguientes se crean con las
/// fábricas que entrega el ``AppContainer``.
struct ProfilesScreen: View {
    @Bindable var viewModel: ProfilesViewModel
    let cameraPreview: CameraPreviewSource
    let makeCalibration: () -> CalibrationViewModel
    let makeCheck: (UUID) -> CheckViewModel

    @State private var path: [Route] = []

    enum Route: Hashable {
        case newProfile
        case check(UUID)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.profiles.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Mi posición")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(.newProfile)
                    } label: {
                        Label("Nueva posición", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .newProfile:
                    CalibrationScreen(viewModel: makeCalibration(), cameraPreview: cameraPreview)
                case .check(let id):
                    CheckScreen(viewModel: makeCheck(id), cameraPreview: cameraPreview)
                }
            }
            .onAppear { viewModel.load() }
            .onChange(of: path) { _, newPath in
                if newPath.isEmpty { viewModel.load() }
            }
            .alert(item: $viewModel.alert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message))
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Aún no hay posiciones", systemImage: "car.side")
        } description: {
            Text("Siéntate como te gusta manejar, pon el móvil en su soporte y guarda esa posición. Cuando te devuelvan el auto, la app te dirá qué ajustar.")
        } actions: {
            Button("Guardar mi posición") {
                path.append(.newProfile)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.profiles) { profile in
                NavigationLink(value: Route.check(profile.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                        Text("Referencia del \(profile.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    viewModel.delete(id: viewModel.profiles[index].id)
                }
            }
        }
    }
}
