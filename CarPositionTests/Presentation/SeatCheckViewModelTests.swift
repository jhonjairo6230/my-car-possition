import XCTest
@testable import CarPosition

@MainActor
final class SeatCheckViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!
    private var scanner: FakeSeatScanner!
    private var profile: DrivingProfile!

    private func makeViewModel() -> SeatCheckViewModel {
        profile = .sample(notes: "Espejos")
        repository = InMemoryProfileRepository([profile])
        scanner = FakeSeatScanner()
        let viewModel = SeatCheckViewModel(
            profileID: profile.id,
            scanner: scanner,
            loadProfile: LoadProfileUseCase(repository: repository),
            checkSeat: CheckSeatUseCase(),
            updateSeat: UpdateSeatUseCase(repository: repository),
            smoothing: 4,
            refreshEvery: 1
        )
        viewModel.onAppear()
        return viewModel
    }

    private func mark(_ viewModel: SeatCheckViewModel, at point: Vector3) {
        scanner.aim(at: point)
        viewModel.mark()
    }

    /// Marca el umbral y deja la guía en la fase del cojín.
    private func makeViewModelOnCushion(sillRear: Vector3 = TestCar.sillRear, sillFront: Vector3 = TestCar.sillFront) -> SeatCheckViewModel {
        let viewModel = makeViewModel()
        mark(viewModel, at: sillRear)
        mark(viewModel, at: sillFront)
        return viewModel
    }

    func testStartsAskingForTheSill() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.phase, .reference(.sillRear))
        XCTAssertEqual(viewModel.profile, profile)
        XCTAssertTrue(scanner.isRunning)
    }

    func testAfterTheSillTheIdealSeatIsDrawn() throws {
        let viewModel = makeViewModelOnCushion()

        XCTAssertEqual(viewModel.phase, .cushion)
        let ghost = try XCTUnwrap(scanner.overlay.markers.first { $0.style == .target })
        XCTAssertEqual((ghost.position - TestCar.cushionFront).length, 0, accuracy: 1e-9)
        XCTAssertTrue(scanner.overlay.segments.contains { $0.style == .target })
    }

    func testTheCushionVerdictFollowsTheSeatLive() {
        let viewModel = makeViewModelOnCushion()

        scanner.aim(at: TestCar.moved(TestCar.cushionFront, forward: -3, up: -2))
        XCTAssertEqual(viewModel.cushionCheck?.adjustments, [.moveSeatForward(centimeters: 3), .raiseSeat(centimeters: 2)])
        XCTAssertEqual(scanner.overlay.markers.last?.style, .current)

        scanner.aim(at: TestCar.cushionFront)
        XCTAssertEqual(viewModel.cushionCheck?.isMatch, true)
        XCTAssertEqual(scanner.overlay.markers.last?.style, .match)
    }

    func testItWorksFromADifferentArkitOrigin() {
        // Otra sesión de ARKit: el mismo auto, girado y desplazado.
        let other: (Vector3) -> Vector3 = { p in Vector3(p.z + 2, p.y - 0.5, -p.x + 1) }
        let viewModel = makeViewModelOnCushion(sillRear: other(TestCar.sillRear), sillFront: other(TestCar.sillFront))

        scanner.aim(at: other(TestCar.cushionFront))

        XCTAssertEqual(viewModel.cushionCheck?.isMatch, true)
    }

    func testTheBackrestAngleIsGuidedLive() throws {
        let viewModel = makeViewModelOnCushion()
        viewModel.next()
        XCTAssertEqual(viewModel.phase, .backrestLower)
        mark(viewModel, at: TestCar.backrestLower)
        XCTAssertEqual(viewModel.phase, .backrestUpper)

        // Respaldo más inclinado: la parte alta 10 cm más atrás.
        scanner.aim(at: TestCar.moved(TestCar.backrestUpper, forward: -10))
        let check = try XCTUnwrap(viewModel.backrestCheck)
        XCTAssertEqual(check.adjustment, .straightenBackrest(degrees: 10))
        XCTAssertEqual(check.targetAngle, 16.7, accuracy: 0.05)
        // Barra actual, barra ideal y el arco entre las dos.
        XCTAssertTrue(scanner.overlay.segments.count > 4)

        scanner.aim(at: TestCar.backrestUpper)
        XCTAssertEqual(viewModel.backrestCheck?.isMatch, true)
    }

    func testSavingTheMeasuredSeatAsTheNewIdeal() {
        let viewModel = makeViewModelOnCushion()
        scanner.aim(at: TestCar.moved(TestCar.cushionFront, forward: 4))
        viewModel.next()
        mark(viewModel, at: TestCar.backrestLower)
        scanner.aim(at: TestCar.backrestUpper)
        viewModel.next()
        XCTAssertEqual(viewModel.phase, .done)
        XCTAssertEqual(viewModel.cushionCheck?.isMatch, false)
        XCTAssertTrue(viewModel.canSaveAsIdeal)

        viewModel.saveAsIdeal()

        XCTAssertEqual(viewModel.alert, .seatUpdated)
        XCTAssertEqual(viewModel.cushionCheck?.isMatch, true)
        XCTAssertEqual(repository.profiles[profile.id]?.seat.cushionFront.x ?? 0, 0.59, accuracy: 1e-9)
    }

    func testMarkingWithoutASurfaceShowsAnAlert() {
        let viewModel = makeViewModel()

        viewModel.mark()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.noSurface))
    }

    func testABadSillIsRejected() {
        let viewModel = makeViewModel()
        mark(viewModel, at: TestCar.sillRear)

        mark(viewModel, at: Vector3(0, 0.8, -0.3))

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.referenceNotHorizontal))
        XCTAssertEqual(viewModel.phase, .reference(.sillFront))
    }

    func testRestartGoesBackToTheSill() {
        let viewModel = makeViewModelOnCushion()
        scanner.aim(at: TestCar.cushionFront)

        viewModel.restart()

        XCTAssertEqual(viewModel.phase, .reference(.sillRear))
        XCTAssertNil(viewModel.cushionCheck)
        XCTAssertEqual(scanner.aimedLandmark, .sillRear)
        XCTAssertTrue(scanner.overlay.markers.isEmpty)
    }
}
