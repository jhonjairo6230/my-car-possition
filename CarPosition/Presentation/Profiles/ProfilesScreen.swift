import SwiftUI

/// Pantalla principal: las posiciones guardadas y la navegación de la app.
///
/// El "+" abre la calibración del asiento con la cámara trasera. Tocar una
/// posición abre su ficha, desde donde se llega a las dos guías.
struct ProfilesScreen: View {
    @Bindable var viewModel: ProfilesViewModel
    let screens: ScreenFactory

    @State private var path: [AppRoute] = []

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
            .navigationDestination(for: AppRoute.self, destination: destination)
            .onAppear { viewModel.load() }
            .onChange(of: path) { _, newPath in
                if newPath.isEmpty { viewModel.load() }
            }
            .alert(item: $viewModel.alert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message))
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .newProfile:
            SeatCalibrationScreen(viewModel: screens.makeSeatCalibration(), preview: screens.seatPreview)
        case .profile(let id):
            ProfileScreen(viewModel: screens.makeProfile(id))
        case .seatCheck(let id):
            SeatCheckScreen(viewModel: screens.makeSeatCheck(id), preview: screens.seatPreview)
        case .headCalibration(let id):
            HeadCalibrationScreen(viewModel: screens.makeHeadCalibration(id), cameraPreview: screens.headPreview)
        case .headCheck(let id):
            HeadCheckScreen(viewModel: screens.makeHeadCheck(id), cameraPreview: screens.headPreview)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Aún no hay posiciones", systemImage: "car.side")
        } description: {
            Text("Deja el asiento como te gusta y márcalo con la cámara trasera. Cuando te devuelvan el auto, la app te guiará con realidad aumentada hasta esa posición.")
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
                NavigationLink(value: AppRoute.profile(profile.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                        Text("Guardada el \(profile.updatedAt.formatted(date: .abbreviated, time: .shortened))")
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
