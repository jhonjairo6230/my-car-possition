import XCTest
@testable import CarPosition

final class HeadEvaluatorTests: XCTestCase {
    private let evaluator = HeadEvaluator()
    private let reference = PostureMeasurement.cm(depth: 60, height: 10, lateral: 0)

    func testTheSamePositionMatches() {
        let evaluation = evaluator.evaluate(current: reference, reference: reference)

        XCTAssertTrue(evaluation.isMatch)
    }

    func testSmallDifferencesAreTolerated() {
        let evaluation = evaluator.evaluate(current: .cm(depth: 61, height: 9, lateral: 2), reference: reference)

        XCTAssertTrue(evaluation.isMatch)
    }

    func testFartherAwayMeansMoveTheSeatForward() {
        let evaluation = evaluator.evaluate(current: .cm(depth: 63.2), reference: reference)

        XCTAssertEqual(evaluation.adjustments, [.moveSeatForward(centimeters: 3)])
        XCTAssertEqual(evaluation.depthOffset, 0.032, accuracy: 1e-9)
    }

    func testCloserMeansMoveTheSeatBackward() {
        let evaluation = evaluator.evaluate(current: .cm(depth: 55), reference: reference)

        XCTAssertEqual(evaluation.adjustments, [.moveSeatBackward(centimeters: 5)])
    }

    func testHigherOrLowerHeadAdjustsTheSeatHeight() {
        XCTAssertEqual(
            evaluator.evaluate(current: .cm(height: 12), reference: reference).adjustments,
            [.lowerSeat(centimeters: 2)]
        )
        XCTAssertEqual(
            evaluator.evaluate(current: .cm(height: 7), reference: reference).adjustments,
            [.raiseSeat(centimeters: 3)]
        )
    }

    func testSidewaysUsesTheDriversLeftAndRight() {
        XCTAssertEqual(
            evaluator.evaluate(current: .cm(lateral: 4), reference: reference).adjustments,
            [.shiftLeft(centimeters: 4)]
        )
        XCTAssertEqual(
            evaluator.evaluate(current: .cm(lateral: -5), reference: reference).adjustments,
            [.shiftRight(centimeters: 5)]
        )
    }

    func testSeveralAdjustmentsComeInOrder() {
        let evaluation = evaluator.evaluate(current: .cm(depth: 65, height: 6, lateral: 5), reference: reference)

        XCTAssertEqual(evaluation.adjustments, [
            .moveSeatForward(centimeters: 5),
            .raiseSeat(centimeters: 4),
            .shiftLeft(centimeters: 5),
        ])
    }

    func testAMovedPhoneHidesTheOtherAdjustments() {
        let tilted = Vector3(0, -cos(10 * Double.pi / 180), sin(10 * Double.pi / 180))

        let evaluation = evaluator.evaluate(current: .cm(depth: 70, gravity: tilted), reference: reference)

        XCTAssertEqual(evaluation.adjustments, [.realignPhone(degrees: 10)])
        XCTAssertEqual(evaluation.phoneTiltChange, 10, accuracy: 1e-6)
    }

    func testCentimetersAreAtLeastOne() {
        XCTAssertEqual(Adjustment.centimeters(0.002), 1)
        XCTAssertEqual(Adjustment.centimeters(-0.026), 3)
    }
}
