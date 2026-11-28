import SwiftUI

/// Punto de entrada de la app.
///
/// Guarda el ``AppContainer`` (que al crearse no construye nada) y, cuando la
/// escena se muestra, le pide la lista de posiciones y las fábricas del resto
/// de pantallas.
@main
struct CarPositionApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ProfilesScreen(viewModel: container.profilesViewModel, screens: container.screens)
        }
    }
}
