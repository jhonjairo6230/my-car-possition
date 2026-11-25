import XCTest
@testable import CarPosition

@MainActor
final class CheckViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!
    private var tracker: FakeHeadTracker!
    private var profile: DrivingProfile!

    private func makeViewModel(reference: PostureMeasurement = .cm(depth: 60, height: 10)) -> CheckViewModel {
        profile = .sample(name: "Mía", notes: "Espejos", reference: reference)
        repository = InMemoryProfileRepository([profile])
        tracker = FakeHeadTracker()
        let viewModel = CheckViewModel(
            profileID: profile.id,
            tracker: tracker,
            loadProfile: LoadProfileUseCase(repository: repository),
            evaluatePosition: EvaluatePositionUseCase(),
            updateReference: UpdateReferenceUseCase(repository: repository),
            updateNotes: UpdateNotesUseCase(repository: repository),
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
        XCTAssertEqual(repository.profiles[profile.id]?.reference.depth ?? 0, 0.66, accuracy: 1e-9)
        XCTAssertEqual(viewModel.evaluation?.isMatch, true)
    }

    func testSavingAReferenceWithoutAStableReadingFails() {
        let viewModel = makeViewModel()
        tracker.emit(.cm(), count: 2)

        viewModel.saveCurrentAsReference()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.notEnoughSamples))
        XCTAssertEqual(repository.profiles[profile.id], profile)
    }

    func testEditingNameAndNotes() {
        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.saveDetails(name: "Lluvia", notes: "Volante arriba"))

        XCTAssertEqual(viewModel.profile?.name, "Lluvia")
        XCTAssertEqual(repository.profiles[profile.id]?.notes, "Volante arriba")
    }

    func testEditingWithAnEmptyNameFails() {
        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.saveDetails(name: " ", notes: ""))
        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.invalidName))
    }

    func testAMissingProfileShowsAnAlert() {
        let viewModel = makeViewModel()
        try? repository.deleteProfile(id: profile.id)

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.profileNotFound))
    }
}
