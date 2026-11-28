import XCTest
@testable import CarPosition

final class AROverlayTests: XCTestCase {
    func testAnArcJoinsTheTwoDirectionsAtTheRadius() throws {
        var overlay = AROverlay()

        overlay.addArc(center: .zero, from: Vector3(0, 1, 0), to: Vector3(1, 0, 0), radius: 0.2, style: .current, steps: 8)

        XCTAssertEqual(overlay.segments.count, 8)
        let first = try XCTUnwrap(overlay.segments.first)
        let last = try XCTUnwrap(overlay.segments.last)
        XCTAssertEqual((first.from - Vector3(0, 0.2, 0)).length, 0, accuracy: 1e-9)
        XCTAssertEqual((last.to - Vector3(0.2, 0, 0)).length, 0, accuracy: 1e-9)
        for segment in overlay.segments {
            XCTAssertEqual(segment.to.length, 0.2, accuracy: 1e-9)
        }
    }

    func testAnArcWithoutDirectionDrawsNothing() {
        var overlay = AROverlay()

        overlay.addArc(center: .zero, from: .zero, to: Vector3(1, 0, 0), radius: 0.2, style: .current)

        XCTAssertTrue(overlay.segments.isEmpty)
    }
}
