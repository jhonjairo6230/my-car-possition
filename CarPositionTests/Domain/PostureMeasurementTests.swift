import XCTest
@testable import CarPosition

final class PostureMeasurementTests: XCTestCase {
    func testNoSamplesGivesNoMeasurement() {
        XCTAssertNil(PostureMeasurement(samples: []))
    }

    func testUsesTheMedianSoOddFramesDoNotCount() throws {
        let samples: [PostureSample] = [
            .cm(depth: 60), .cm(depth: 61), .cm(depth: 90), .cm(depth: 59), .cm(depth: 60),
        ]

        let measurement = try XCTUnwrap(PostureMeasurement(samples: samples))

        XCTAssertEqual(measurement.depth, 0.60, accuracy: 1e-9)
        XCTAssertEqual(measurement.sampleCount, 5)
    }

    func testMedianOfAnEvenCountIsTheMeanOfTheMiddleTwo() {
        XCTAssertEqual(PostureMeasurement.median([4, 1, 3, 2]), 2.5)
    }

    func testGravityIsAveragedAndNormalized() throws {
        let measurement = try XCTUnwrap(PostureMeasurement(samples: [
            .cm(gravity: Vector3(0, -1, 0)),
            .cm(gravity: Vector3(0, -1, 0.1)),
            .cm(gravity: Vector3(0, -1, -0.1)),
        ]))

        XCTAssertEqual(measurement.deviceGravity.length, 1, accuracy: 1e-9)
        XCTAssertEqual(measurement.deviceGravity.z, 0, accuracy: 1e-9)
    }
}
