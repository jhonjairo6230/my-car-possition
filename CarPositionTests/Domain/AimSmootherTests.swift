import XCTest
@testable import CarPosition

final class AimSmootherTests: XCTestCase {
    func testNeedsHalfTheWindowBeforeGivingAValue() {
        var smoother = AimSmoother(capacity: 4)
        smoother.add(.cm(1, 1, 1))
        XCTAssertNil(smoother.value)

        smoother.add(.cm(1, 1, 1))
        XCTAssertEqual(smoother.value, .cm(1, 1, 1))
    }

    func testUsesTheMedianSoASingleJumpDoesNotCount() throws {
        var smoother = AimSmoother(capacity: 5)
        for x in [10.0, 11, 80, 9, 10] {
            smoother.add(.cm(x, 0, 0))
        }

        XCTAssertEqual(try XCTUnwrap(smoother.value).x, 0.10, accuracy: 1e-9)
    }

    func testKeepsOnlyTheLastPoints() throws {
        var smoother = AimSmoother(capacity: 3)
        for x in [1.0, 2, 3, 50, 50, 50] {
            smoother.add(.cm(x, 0, 0))
        }

        XCTAssertEqual(try XCTUnwrap(smoother.value).x, 0.50, accuracy: 1e-9)
    }

    func testLosingTheSurfaceClearsTheWindow() {
        var smoother = AimSmoother(capacity: 2)
        smoother.add(.cm(1, 1, 1))
        smoother.add(.cm(1, 1, 1))

        smoother.add(nil)

        XCTAssertNil(smoother.value)
    }
}
