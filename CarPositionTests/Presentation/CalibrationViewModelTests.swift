import XCTest
@testable import CarPosition

@MainActor
final class CalibrationViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!
    private var tracker: FakeHeadTracker!

    private func makeViewModel(samplesNeeded: Int = 5, maxFrames: Int = 20) -> CalibrationViewModel {
        repository = InMemoryProfileRepository()
        tracker = FakeHeadTracker()
        let viewModel = CalibrationViewModel(
            tracker: tracker,
            createProfile: CreateProfileUseCase(repository: repository),
            countdownSeconds: 3,
            samplesNeeded: samplesNeeded,
            maxFrames: maxFrames,
            refreshEvery: 1,
            sleep: { _ in } // Sin esperas reales.
        )
        viewModel.onAppear()
        return viewModel
    }

    func testAppearingStartsTheCameraAndDisappearingStopsIt() {
        let viewModel = makeViewModel()
        XCTAssertTrue(tracker.isRunning)

        viewModel.onDisappear()

        XCTAssertFalse(tracker.isRunning)
        XCTAssertNil(tracker.onSample)
    }

    func testShowsWhetherTheFaceIsSeenAndHowFar() {
        let viewModel = makeViewModel()

        tracker.emit(.cm(depth: 62))
        XCTAssertTrue(viewModel.isFaceDetected)
        XCTAssertEqual(viewModel.distanceCentimeters, 62)

        tracker.emit(nil)
        XCTAssertFalse(viewModel.isFaceDetected)
        XCTAssertNil(viewModel.distanceCentimeters)
    }

    func testSamplesBeforeTheCountdownEndsAreIgnored() {
        let viewModel = makeViewModel()

        tracker.emit(.cm(), count: 10)

        XCTAssertEqual(viewModel.phase, .ready)
        XCTAssertTrue(repository.profiles.isEmpty)
    }

    func testCalibratingSavesTheMedianPosition() async throws {
        let viewModel = makeViewModel(samplesNeeded: 5)
        viewModel.name = "  Mía "
        viewModel.notes = "Volante 2ª muesca"

        await viewModel.startCapture()?.value
        XCTAssertEqual(viewModel.phase, .capturing(progress: 0))

        tracker.emit(nil, count: 3) // Fotogramas sin cara: no cuentan.
        for depth in [60.0, 61, 59, 60, 95] {
            tracker.emit(.cm(depth: depth))
        }

        guard case .saved(let profile) = viewModel.phase else {
            return XCTFail("Se esperaba .saved y es \(viewModel.phase)")
        }
        XCTAssertEqual(profile.name, "Mía")
        XCTAssertEqual(profile.notes, "Volante 2ª muesca")
        XCTAssertEqual(profile.reference.depth, 0.60, accuracy: 1e-9)
        XCTAssertEqual(profile.reference.sampleCount, 5)
        XCTAssertEqual(repository.profiles[profile.id], profile)
    }

    func testGivesUpIfTheFaceIsNotSeenInTime() async {
        let viewModel = makeViewModel(samplesNeeded: 5, maxFrames: 10)

        await viewModel.startCapture()?.value
        tracker.emit(.cm(), count: 2)
        tracker.emit(nil, count: 8)

        XCTAssertEqual(viewModel.phase, .ready)
        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.faceNotFound))
        XCTAssertTrue(repository.profiles.isEmpty)
    }

    func testAnEmptyNameShowsAnAlertAndDoesNotStart() {
        let viewModel = makeViewModel()
        viewModel.name = "  "

        XCTAssertFalse(viewModel.canStart)
        XCTAssertNil(viewModel.startCapture())
        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.invalidName))
        XCTAssertEqual(viewModel.phase, .ready)
    }

    func testCancellingGoesBackToReady() async {
        let viewModel = makeViewModel()
        await viewModel.startCapture()?.value

        viewModel.cancelCapture()
        tracker.emit(.cm(), count: 10)

        XCTAssertEqual(viewModel.phase, .ready)
        XCTAssertTrue(repository.profiles.isEmpty)
    }

    func testUnsupportedDevicesCannotStart() {
        let viewModel = makeViewModel()
        tracker.isSupported = false

        XCTAssertFalse(viewModel.isSupported)
        XCTAssertFalse(viewModel.canStart)
    }
}
