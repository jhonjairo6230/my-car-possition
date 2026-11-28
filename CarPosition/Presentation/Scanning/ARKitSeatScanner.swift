import ARKit
import SceneKit
import UIKit

/// Cámara trasera con **seguimiento del mundo de ARKit**: encuentra el punto
/// del asiento bajo la mira y dibuja en realidad aumentada la guía.
///
/// Es el único archivo que usa ARKit para el asiento (el de la cara es
/// `ARKitHeadTracker`). En cada fotograma lanza un rayo desde el centro de la
/// pantalla contra las superficies que ARKit reconoce y entrega el punto de
/// choque. Con LiDAR activa la reconstrucción de la escena, que hace esos
/// rayos más precisos sobre la tapicería.
@MainActor
final class ARKitSeatScanner: NSObject, SeatScanner, CameraPreviewSource {
    var onAim: ((Vector3?) -> Void)?
    var onTrackingChange: ((Bool) -> Void)?
    var aimedLandmark: SeatLandmark?

    var isSupported: Bool { ARWorldTrackingConfiguration.isSupported }

    private let session = ARSession()
    private let overlayNode = SCNNode()
    private var isRunning = false

    private lazy var sceneView: ARSCNView = {
        let view = ARSCNView(frame: .zero)
        view.session = session
        view.scene = SCNScene()
        view.scene.rootNode.addChildNode(overlayNode)
        view.automaticallyUpdatesLighting = false

        // Las instrucciones de Apple para "mueve el móvil" mientras ARKit
        // reconoce el entorno.
        let coaching = ARCoachingOverlayView()
        coaching.session = session
        coaching.goal = .anyPlane
        coaching.activatesAutomatically = true
        coaching.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coaching)
        NSLayoutConstraint.activate([
            coaching.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coaching.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coaching.topAnchor.constraint(equalTo: view.topAnchor),
            coaching.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return view
    }()

    var previewView: UIView { sceneView }

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard isSupported, !isRunning else { return }
        _ = sceneView // La vista debe existir para lanzar rayos desde su centro.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.worldAlignment = .gravity
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stop() {
        guard isRunning else { return }
        session.pause()
        isRunning = false
        overlayNode.childNodes.forEach { $0.removeFromParentNode() }
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func show(_ overlay: AROverlay) {
        overlayNode.childNodes.forEach { $0.removeFromParentNode() }
        for marker in overlay.markers {
            overlayNode.addChildNode(Self.sphere(at: marker.position, style: marker.style))
        }
        for segment in overlay.segments {
            if let bar = Self.bar(from: segment.from, to: segment.to, style: segment.style) {
                overlayNode.addChildNode(bar)
            }
        }
    }

    // MARK: - Rayo desde la mira

    /// El punto del mundo bajo el centro de la pantalla. Primero prueba con
    /// los planos ya detectados (más estables) y, si no, con una estimación.
    private func aimPoint() -> Vector3? {
        let bounds = sceneView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for target in [ARRaycastQuery.Target.existingPlaneGeometry, .estimatedPlane] {
            guard let query = sceneView.raycastQuery(from: center, allowing: target, alignment: .any) else {
                continue
            }
            if let hit = session.raycast(query).first {
                return Vector3(hit.worldTransform.columns.3)
            }
        }
        return nil
    }

    // MARK: - Dibujo con SceneKit

    private static func color(_ style: AROverlay.Style) -> UIColor {
        switch style {
        case .reference: return .systemBlue
        case .target: return UIColor.systemGreen.withAlphaComponent(0.55)
        case .current: return .systemOrange
        case .match: return .systemGreen
        }
    }

    /// Material sin luces y que se dibuja por encima de todo: la guía se ve
    /// aunque quede "dentro" de la tapicería.
    private static func material(_ style: AROverlay.Style) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color(style)
        material.lightingModel = .constant
        material.readsFromDepthBuffer = false
        return material
    }

    private static func sphere(at position: Vector3, style: AROverlay.Style) -> SCNNode {
        let sphere = SCNSphere(radius: style == .target ? 0.02 : 0.012)
        sphere.materials = [material(style)]
        let node = SCNNode(geometry: sphere)
        node.simdPosition = position.simdVector
        node.renderingOrder = 100
        return node
    }

    private static func bar(from: Vector3, to: Vector3, style: AROverlay.Style) -> SCNNode? {
        let start = from.simdVector
        let end = to.simdVector
        let length = simd_distance(start, end)
        guard length > 0.0005 else { return nil }
        let cylinder = SCNCylinder(radius: style == .target ? 0.006 : 0.004, height: CGFloat(length))
        cylinder.materials = [material(style)]
        let node = SCNNode(geometry: cylinder)
        node.simdPosition = (start + end) / 2
        // El cilindro de SceneKit apunta hacia +y: se gira hacia la dirección del tramo.
        node.simdOrientation = simd_quatf(from: simd_float3(0, 1, 0), to: simd_normalize(end - start))
        node.renderingOrder = 100
        return node
    }
}

extension ARKitSeatScanner: ARSessionDelegate {
    /// ARKit llama aquí en el hilo principal (la sesión no tiene otra cola).
    /// No se guarda el `ARFrame`: retenerlo bloquea la cámara.
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        MainActor.assumeIsolated {
            onAim?(aimPoint())
        }
    }

    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let isReady: Bool
        if case .normal = camera.trackingState {
            isReady = true
        } else {
            isReady = false
        }
        MainActor.assumeIsolated {
            onTrackingChange?(isReady)
        }
    }
}
