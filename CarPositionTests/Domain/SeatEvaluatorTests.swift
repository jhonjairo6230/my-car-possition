import XCTest
@testable import CarPosition

final class SeatEvaluatorTests: XCTestCase {
    private let evaluator = SeatEvaluator()
    private let target = Vector3.cm(55, 30, 45)

    func testBackrestAngleIsMeasuredFromTheVertical() {
        XCTAssertEqual(SeatPosition.backrestAngle(lower: .cm(0, 0, 0), upper: .cm(0, 50, 0)), 0, accuracy: 1e-9)
        XCTAssertEqual(SeatPosition.backrestAngle(lower: .cm(0, 0, 0), upper: .cm(-50, 50, 0)), 45, accuracy: 1e-9)
        XCTAssertEqual(TestCar.seat.backrestAngle, 16.699, accuracy: 0.01)
    }

    func testBackrestAngleIgnoresTheSide() {
        XCTAssertEqual(
            SeatPosition.backrestAngle(lower: .cm(0, 0, 0), upper: .cm(-10, 50, 7)),
            SeatPosition.backrestAngle(lower: .cm(0, 0, 0), upper: .cm(-10, 50, 0)),
            accuracy: 1e-9
        )
    }

    func testSameCushionMatches() {
        XCTAssertTrue(evaluator.cushion(current: target, target: target).isMatch)
        XCTAssertTrue(evaluator.cushion(current: .cm(56, 29, 40), target: target).isMatch)
    }

    func testCushionTooFarForwardMeansMoveBack() {
        let check = evaluator.cushion(current: .cm(58, 30, 45), target: target)

        XCTAssertEqual(check.adjustments, [.moveSeatBackward(centimeters: 3)])
        XCTAssertEqual(check.forwardOffset, 0.03, accuracy: 1e-9)
    }

    func testCushionTooFarBackAndLowMeansForwardAndUp() {
        let check = evaluator.cushion(current: .cm(50, 27, 45), target: target)

        XCTAssertEqual(check.adjustments, [.moveSeatForward(centimeters: 5), .raiseSeat(centimeters: 3)])
    }

    func testCushionTooHighMeansLower() {
        XCTAssertEqual(evaluator.cushion(current: .cm(55, 32, 45), target: target).adjustments, [.lowerSeat(centimeters: 2)])
    }

    func testBackrest() {
        XCTAssertTrue(evaluator.backrest(currentAngle: 16, targetAngle: 17).isMatch)
        XCTAssertEqual(evaluator.backrest(currentAngle: 22, targetAngle: 17).adjustment, .straightenBackrest(degrees: 5))
        XCTAssertEqual(evaluator.backrest(currentAngle: 12.4, targetAngle: 17).adjustment, .reclineBackrest(degrees: 5))
        XCTAssertEqual(evaluator.backrest(currentAngle: 22, targetAngle: 17).angleOffset, 5, accuracy: 1e-9)
    }

    func testRoundingIsAtLeastOne() {
        XCTAssertEqual(Adjustment.centimeters(0.002), 1)
        XCTAssertEqual(Adjustment.centimeters(-0.026), 3)
        XCTAssertEqual(Adjustment.degrees(0.3), 1)
        XCTAssertEqual(Adjustment.degrees(-4.6), 5)
    }
}
