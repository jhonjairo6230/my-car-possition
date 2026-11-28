import XCTest
@testable import CarPosition

@MainActor
final class SeatCalibrationViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!
    private var scanner: FakeSeatScanner!

    private func makeViewModel() -> SeatCalibrationViewModel {
        repository = InMemoryProfileRepository()
        scanner = FakeSeatScanner()
        let viewModel = SeatCalibrationViewModel(
            scanner: scanner,
            createProfile: CreateProfileUseCase(repository: repository),
            smoothing: 4,
            refreshEvery: 1
        )
        viewModel.onAppear()
        return viewModel
    }

    private func mark(_ viewModel: SeatCalibrationViewModel, at point: Vector3) {
        scanner.aim(at: point)
        viewModel.mark()
    }

    private func markWholeSeat(_ viewModel: SeatCalibrationViewModel) {
        mark(viewModel, at: TestCar.sillRear)
        mark(viewModel, at: TestCar.sillFront)
        mark(viewModel, at: TestCar.cushionFront)
        mark(viewModel, at: TestCar.backrestLower)
        mark(viewModel, at: TestCar.backrestUpper)
    }

    func testAppearingStartsTheCameraAndAsksForTheFirstPoint() {
        let viewModel = makeViewModel()

        XCTAssertTrue(scanner.isRunning)
        XCTAssertEqual(viewModel.step, .marking(.sillRear))
        XCTAssertEqual(scanner.aimedLandmark, .sillRear)
    }

    func testMarkingAllPointsAndSavingCreatesTheProfile() throws {
        let viewModel = makeViewModel()

        markWholeSeat(viewModel)
        XCTAssertEqual(viewModel.step, .naming)
        XCTAssertEqual(try XCTUnwrap(viewModel.backrestAngle), 16.7, accuracy: 0.05)

        viewModel.name = "Mía"
        viewModel.notes = "Espejo izquierdo: ver la manija"
        viewModel.save()

        guard case .saved(let profile) = viewModel.step else {
            return XCTFail("Se esperaba .saved y es \(viewModel.step)")
        }
        XCTAssertEqual(profile.name, "Mía")
        XCTAssertEqual((profile.seat.cushionFront - TestCar.seat.cushionFront).length, 0, accuracy: 1e-9)
        XCTAssertEqual(profile.seat.backrestAngle, TestCar.seat.backrestAngle, accuracy: 1e-9)
        XCTAssertNil(profile.head)
        XCTAssertEqual(repository.profiles[profile.id], profile)
    }

    func testEachMarkAsksForTheNextPoint() {
        let viewModel = makeViewModel()

        mark(viewModel, at: TestCar.sillRear)

        XCTAssertEqual(viewModel.step, .marking(.sillFront))
        XCTAssertEqual(scanner.aimedLandmark, .sillFront)
        XCTAssertEqual(viewModel.markedCount, 1)
    }

    func testMarkingWithoutASurfaceShowsAnAlert() {
        let viewModel = makeViewModel()

        viewModel.mark()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.noSurface))
        XCTAssertEqual(viewModel.step, .marking(.sillRear))
    }

    func testASillThatIsTooShortIsRejected() {
        let viewModel = makeViewModel()
        mark(viewModel, at: TestCar.sillRear)

        mark(viewModel, at: Vector3(0, 0, -0.1))

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.referenceTooShort))
        XCTAssertEqual(viewModel.step, .marking(.sillFront))
    }

    func testUndoGoesBackOnePoint() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.canUndo)
        mark(viewModel, at: TestCar.sillRear)
        mark(viewModel, at: TestCar.sillFront)

        viewModel.undo()

        XCTAssertEqual(viewModel.step, .marking(.sillFront))
        XCTAssertEqual(scanner.aimedLandmark, .sillFront)
        XCTAssertEqual(scanner.overlay.markers.count, 1)
    }

    func testMarkedPointsAreDrawn() {
        let viewModel = makeViewModel()
        mark(viewModel, at: TestCar.sillRear)
        mark(viewModel, at: TestCar.sillFront)
        mark(viewModel, at: TestCar.cushionFront)

        XCTAssertEqual(scanner.overlay.markers.map(\.style), [.reference, .reference, .current])
        XCTAssertEqual(scanner.overlay.segments, [.init(from: TestCar.sillRear, to: TestCar.sillFront, style: .reference)])
    }

    func testSavingWithAnEmptyNameFails() {
        let viewModel = makeViewModel()
        markWholeSeat(viewModel)
        viewModel.name = " "

        viewModel.save()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.invalidName))
        XCTAssertEqual(viewModel.step, .naming)
    }

    func testDisappearingStopsTheCamera() {
        let viewModel = makeViewModel()

        viewModel.onDisappear()

        XCTAssertFalse(scanner.isRunning)
        XCTAssertNil(scanner.onAim)
    }
}
