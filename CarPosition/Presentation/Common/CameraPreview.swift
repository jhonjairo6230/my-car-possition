import SwiftUI
import UIKit

/// Algo que sabe enseñar lo que ve la cámara.
///
/// Está separado de ``HeadTracker`` para que los ViewModel no dependan de
/// UIKit: ellos solo reciben lecturas; la vista es cosa de la pantalla.
@MainActor
protocol CameraPreviewSource: AnyObject {
    var previewView: UIView { get }
}

/// Puente entre SwiftUI y UIKit: muestra la vista de la cámara.
///
/// La vista de la cámara es **la misma** en todas las pantallas (hay una
/// sola sesión de ARKit). UIKit la cambia de sitio sola al añadirla a otra
/// pantalla.
struct CameraPreview: UIViewRepresentable {
    let source: CameraPreviewSource

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.backgroundColor = .black
        let preview = source.previewView
        preview.removeFromSuperview()
        preview.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            preview.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            preview.topAnchor.constraint(equalTo: container.topAnchor),
            preview.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
