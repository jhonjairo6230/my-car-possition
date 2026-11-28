import XCTest
@testable import CarPosition

final class CarFrameTests: XCTestCase {
    func testAxesFollowTheSillAndGravity() throws {
        let frame = try CarFrame(sillRear: .zero, sillFront: Vector3(0, 0, -1))

        XCTAssertEqual(frame.forward, Vector3(0, 0, -1))
        XCTAssertEqual(frame.up, Vector3(0, 1, 0))
        XCTAssertEqual(frame.local(Vector3(0.45, 0.30, -0.55)), Vector3(0.55, 0.30, 0.45))
    }

    func testLocalAndWorldAreInverse() throws {
        let frame = try CarFrame(sillRear: Vector3(1, 0.2, 3), sillFront: Vector3(1.6, 0.25, 2.2))
        let point = Vector3(0.3, 0.9, 2.7)

        let roundTrip = frame.world(frame.local(point))

        XCTAssertEqual((roundTrip - point).length, 0, accuracy: 1e-9)
    }

    func testTheSameSeatMeasuresTheSameFromAnyArkitOrigin() throws {
        // Dos sesiones de ARKit con orígenes y orientaciones distintos.
        let first = try CarFrame(sillRear: .zero, sillFront: Vector3(0, 0, -1))
        let rotate: (Vector3) -> Vector3 = { p in Vector3(p.z + 2, p.y - 0.5, -p.x + 1) } // 90° + traslación
        let second = try CarFrame(sillRear: rotate(.zero), sillFront: rotate(Vector3(0, 0, -1)))
        let cushion = Vector3(0.45, 0.30, -0.55)

        let a = first.local(cushion)
        let b = second.local(rotate(cushion))

        XCTAssertEqual((a - b).length, 0, accuracy: 1e-9)
    }

    func testASlopeDoesNotChangeTheSeatMeasurements() throws {
        // Auto aparcado cuesta arriba (8°): todo el auto gira alrededor del umbral trasero.
        let angle = 8.0 * .pi / 180
        let tilt: (Vector3) -> Vector3 = { p in
            // Giro alrededor del eje x del mundo: el morro (-z) sube.
            Vector3(p.x, p.y * cos(angle) - p.z * sin(angle), p.y * sin(angle) + p.z * cos(angle))
        }
        let flat = try CarFrame(sillRear: .zero, sillFront: Vector3(0, 0, -1))
        let sloped = try CarFrame(sillRear: tilt(.zero), sillFront: tilt(Vector3(0, 0, -1)))
        let cushion = Vector3(0.45, 0.30, -0.55)

        XCTAssertEqual(sloped.pitchDegrees, 8, accuracy: 1e-6)
        XCTAssertEqual((flat.local(cushion) - sloped.local(tilt(cushion))).length, 0, accuracy: 1e-9)
    }

    func testPointsTooCloseAreRejected() {
        XCTAssertThrowsError(try CarFrame(sillRear: .zero, sillFront: Vector3(0, 0, -0.2))) { error in
            XCTAssertEqual(error as? PositionError, .referenceTooShort)
        }
    }

    func testAVerticalLineIsNotASill() {
        XCTAssertThrowsError(try CarFrame(sillRear: .zero, sillFront: Vector3(0, 0.8, -0.3))) { error in
            XCTAssertEqual(error as? PositionError, .referenceNotHorizontal)
        }
    }
}
