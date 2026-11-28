import XCTest
@testable import CarPosition

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!

    private func makeViewModel(_ profile: DrivingProfile) -> ProfileViewModel {
        repository = InMemoryProfileRepository([profile])
        let viewModel = ProfileViewModel(
            profileID: profile.id,
            loadProfile: LoadProfileUseCase(repository: repository),
            updateNotes: UpdateNotesUseCase(repository: repository)
        )
        viewModel.load()
        return viewModel
    }

    func testKnowsWhetherTheHeadIsCalibrated() {
        XCTAssertFalse(makeViewModel(.sample(head: nil)).hasHeadReference)
        XCTAssertTrue(makeViewModel(.sample(head: .cm())).hasHeadReference)
    }

    func testEditingNameAndNotes() {
        let profile = DrivingProfile.sample()
        let viewModel = makeViewModel(profile)

        XCTAssertTrue(viewModel.saveDetails(name: "Lluvia", notes: "Volante arriba"))

        XCTAssertEqual(viewModel.profile?.name, "Lluvia")
        XCTAssertEqual(repository.profiles[profile.id]?.notes, "Volante arriba")
    }

    func testEditingWithAnEmptyNameFails() {
        let viewModel = makeViewModel(.sample())

        XCTAssertFalse(viewModel.saveDetails(name: " ", notes: ""))
        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.invalidName))
    }

    func testAMissingProfileShowsAnAlert() {
        let profile = DrivingProfile.sample()
        let viewModel = makeViewModel(profile)
        try? repository.deleteProfile(id: profile.id)

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.profileNotFound))
    }
}
