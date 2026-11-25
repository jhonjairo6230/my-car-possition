import XCTest
@testable import CarPosition

final class PostureGeometryTests: XCTestCase {
    /// Móvil vertical, mirando hacia -z (ejes de la cámara = ejes del mundo).
    private func uprightSample(head: Vector3) -> PostureSample {
        PostureGeometry.sample(
            cameraPosition: .zero,
            cameraRight: Vector3(1, 0, 0),
            cameraUp: Vector3(0, 1, 0),
            cameraBack: Vector3(0, 0, 1),
            headPosition: head
        )
    }

    func testHeadStraightInFrontGivesDepthAndHeight() {
        let sample = uprightSample(head: Vector3(0, 0.2, -0.6))

        XCTAssertEqual(sample.depth, 0.6, accuracy: 1e-9)
        XCTAssertEqual(sample.height, 0.2, accuracy: 1e-9)
        XCTAssertEqual(sample.lateral, 0, accuracy: 1e-9)
    }

    func testHeadOnTheCameraRightIsOnTheDriversLeft() {
        // El conductor mira a la cámara: la derecha de la cámara es su izquierda.
        let sample = uprightSample(head: Vector3(0.1, 0, -0.6))

        XCTAssertEqual(sample.lateral, -0.1, accuracy: 1e-9)
    }

    func testDepthIsPositiveEvenIfTheCameraAxisPointsAway() {
        let sample = PostureGeometry.sample(
            cameraPosition: .zero,
            cameraRight: Vector3(-1, 0, 0),
            cameraUp: Vector3(0, 1, 0),
            cameraBack: Vector3(0, 0, -1),
            headPosition: Vector3(0, 0, -0.6)
        )

        XCTAssertEqual(sample.depth, 0.6, accuracy: 1e-9)
    }

    func testCameraPositionIsSubtracted() {
        let sample = PostureGeometry.sample(
            cameraPosition: Vector3(1, 1, 1),
            cameraRight: Vector3(1, 0, 0),
            cameraUp: Vector3(0, 1, 0),
            cameraBack: Vector3(0, 0, 1),
            headPosition: Vector3(1, 1.15, 0.5)
        )

        XCTAssertEqual(sample.depth, 0.5, accuracy: 1e-9)
        XCTAssertEqual(sample.height, 0.15, accuracy: 1e-9)
    }

    func testHeightFollowsGravityWhenThePhoneIsTilted() {
        // Móvil inclinado 30° hacia atrás: la altura sigue siendo vertical.
        let angle = 30.0 * .pi / 180
        let sample = PostureGeometry.sample(
            cameraPosition: .zero,
            cameraRight: Vector3(1, 0, 0),
            cameraUp: Vector3(0, cos(angle), sin(angle)),
            cameraBack: Vector3(0, -sin(angle), cos(angle)),
            headPosition: Vector3(0, 0.25, -0.5)
        )

        XCTAssertEqual(sample.height, 0.25, accuracy: 1e-9)
        XCTAssertEqual(sample.depth, 0.5, accuracy: 1e-9)
    }

    func testGravityIsExpressedInPhoneAxes() {
        XCTAssertEqual(uprightSample(head: Vector3(0, 0, -0.6)).deviceGravity, Vector3(0, -1, 0))

        // Móvil en horizontal: su eje x apunta hacia arriba.
        let landscape = PostureGeometry.sample(
            cameraPosition: .zero,
            cameraRight: Vector3(0, 1, 0),
            cameraUp: Vector3(-1, 0, 0),
            cameraBack: Vector3(0, 0, 1),
            headPosition: Vector3(0, 0, -0.6)
        )
        XCTAssertEqual(landscape.deviceGravity, Vector3(-1, 0, 0))
    }
}
