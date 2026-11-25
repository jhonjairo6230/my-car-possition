import XCTest
@testable import CarPosition

@MainActor
final class ProfilesViewModelTests: XCTestCase {
    private var repository: InMemoryProfileRepository!

    private func makeViewModel(_ profiles: [DrivingProfile] = []) -> ProfilesViewModel {
        repository = InMemoryProfileRepository(profiles)
        return ProfilesViewModel(
            listProfiles: ListProfilesUseCase(repository: repository),
            deleteProfile: DeleteProfileUseCase(repository: repository)
        )
    }

    func testLoadShowsProfilesMostRecentFirst() {
        let viewModel = makeViewModel([
            .sample(name: "Vieja", updatedAt: Date(timeIntervalSince1970: 1)),
            .sample(name: "Nueva", updatedAt: Date(timeIntervalSince1970: 2)),
        ])

        viewModel.load()

        XCTAssertEqual(viewModel.profiles.map(\.name), ["Nueva", "Vieja"])
    }

    func testDeleteRemovesTheProfile() {
        let profile = DrivingProfile.sample()
        let viewModel = makeViewModel([profile])
        viewModel.load()

        viewModel.delete(id: profile.id)

        XCTAssertTrue(viewModel.profiles.isEmpty)
        XCTAssertNil(repository.profiles[profile.id])
    }

    func testStorageErrorsBecomeAnAlert() {
        let viewModel = makeViewModel()
        repository.error = .storageFailed

        viewModel.load()

        XCTAssertEqual(viewModel.alert, AlertMessage(error: PositionError.storageFailed))
    }
}
