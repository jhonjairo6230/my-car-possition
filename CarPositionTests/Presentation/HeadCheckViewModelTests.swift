import XCTest
@testable import CarPosition

@MainActor
final class HeadCheckViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!
    private var tracker: FakeHeadTracker!
    private var profile: DrivingProfile!

    private func makeViewModel(reference: PostureMeasurement = .cm(depth: 60, height: 10)) -> HeadCheckViewModel {
        profile = .sample(name: "Mía", notes: "Espejos", head: reference)
        repository = InMemoryProfileRepository([profile])
        tracker = FakeHeadTracker()
        let viewModel = HeadCheckViewModel(
            profileID: profile.id,
            tracker: tracker,
            loadProfile: LoadProfileUseCase(repository: repository),
            evaluatePosition: EvaluateHeadUseCase(),
            updateReference: UpdateHeadReferenceUseCase(repository: repository),
            windowSize: 10,
            minimumSamples: 5,
            refreshEvery: 1
        )
        viewModel.onAppear()
        return viewModel
    }

    func testAppearingLoadsTheProfileAndStartsTheCamera() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.profile, profile)
        XCTAssertTrue(tracker.isRunning)
    }

    func testNoVerdictUntilThereAreEnoughSamples() {
        let viewModel = makeViewModel()

        tracker.emit(.cm(), count: 4)

        XCTAssertTrue(viewModel.isFaceDetected)
        XCTAssertNil(viewModel.evaluation)
    }

    func testSamePositionMatches() {
        let viewModel = makeViewModel()

        tracker.emit(.cm(depth: 60, height: 10), count: 5)

        XCTAssertEqual(viewModel.evaluation?.isMatch, true)
    }

    func testTheVerdictFollowsTheSeatLive() {
        let viewModel = makeViewModel()

        tracker.emit(.cm(depth: 64), count: 10)
        XCTAssertEqual(viewModel.evaluation?.adjustments, [.moveSeatForward(centimeters: 4)])

        // El conductor adelanta el asiento: la ventana se llena de lecturas nuevas.
        tracker.emit(.cm(depth: 60), count: 10)
        XCTAssertEqual(viewModel.evaluation?.isMatch, true)
    }

    func testLosingTheFaceClearsTheWindow() {
        let viewModel = makeViewModel()
        tracker.emit(.cm(depth: 70), count: 10)

        tracker.emit(nil)
        XCTAssertFalse(viewModel.isFaceDetected)

        tracker.emit(.cm(depth: 60), count: 5)
        XCTAssertEqual(viewModel.evaluation?.isMatch, true)
    }

    func testSavingTheCurrentPositionAsReference() {
        let viewModel = makeViewModel()
        tracker.emit(.cm(depth: 66), count: 10)

        viewModel.saveCurrentAsReference()

        XCTAssertEqual(viewModel.alert, .referenceUpdated)
        XCTAssertEqual(repository.profiles[profile.id]?.head?.depth ?? 0, 0.66, accuracy: 1e-9)
        XCTAssertEqual(viewModel.evaluation?.isMatch, true)
    }

    func testSavingAReferenceWithoutAStableReadingFails() {
        let viewModel = makeViewModel()
        tracker.emit(.cm(), count: 2)

        viewModel.saveCurrentAsReference()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.notEnoughSamples))
        XCTAssertEqual(repository.profiles[profile.id], profile)
    }

    func testAMissingProfileShowsAnAlert() {
        let viewModel = makeViewModel()
        try? repository.deleteProfile(id: profile.id)

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.profileNotFound))
    }
}
