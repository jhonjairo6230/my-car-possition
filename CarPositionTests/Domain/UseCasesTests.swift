import XCTest
@testable import CarPosition

final class UseCasesTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_000)
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func testCreateProfileTrimsAndSaves() throws {
        let repository = InMemoryProfileRepository()
        let useCase = CreateProfileUseCase(repository: repository, now: { self.fixedDate }, makeID: { self.fixedID })

        let profile = try useCase.execute(name: "  Mi posición ", notes: " Volante 2 \n", reference: .cm())

        XCTAssertEqual(profile.name, "Mi posición")
        XCTAssertEqual(profile.notes, "Volante 2")
        XCTAssertEqual(profile.createdAt, fixedDate)
        XCTAssertEqual(repository.profiles[fixedID], profile)
    }

    func testCreateProfileRejectsAnEmptyName() {
        let repository = InMemoryProfileRepository()
        let useCase = CreateProfileUseCase(repository: repository)

        XCTAssertThrowsError(try useCase.execute(name: "   ", notes: "", reference: .cm())) { error in
            XCTAssertEqual(error as? PositionError, .invalidName)
        }
        XCTAssertTrue(repository.profiles.isEmpty)
    }

    func testUpdateReferenceKeepsNameAndNotes() throws {
        let original = DrivingProfile.sample(name: "Yo", notes: "Espejos", reference: .cm(depth: 60))
        let repository = InMemoryProfileRepository([original])
        let useCase = UpdateReferenceUseCase(repository: repository, now: { self.fixedDate })

        let updated = try useCase.execute(id: original.id, reference: .cm(depth: 65))

        XCTAssertEqual(updated.reference, .cm(depth: 65))
        XCTAssertEqual(updated.name, "Yo")
        XCTAssertEqual(updated.notes, "Espejos")
        XCTAssertEqual(updated.updatedAt, fixedDate)
        XCTAssertEqual(repository.profiles[original.id], updated)
    }

    func testUpdateReferenceOfAMissingProfileFails() {
        let useCase = UpdateReferenceUseCase(repository: InMemoryProfileRepository())

        XCTAssertThrowsError(try useCase.execute(id: UUID(), reference: .cm())) { error in
            XCTAssertEqual(error as? PositionError, .profileNotFound)
        }
    }

    func testUpdateNotesKeepsTheReference() throws {
        let original = DrivingProfile.sample(reference: .cm(depth: 61))
        let repository = InMemoryProfileRepository([original])

        let updated = try UpdateNotesUseCase(repository: repository)
            .execute(id: original.id, name: "Otra", notes: "Volante abajo")

        XCTAssertEqual(updated.name, "Otra")
        XCTAssertEqual(updated.notes, "Volante abajo")
        XCTAssertEqual(updated.reference, .cm(depth: 61))
    }

    func testLoadProfileOfAMissingProfileFails() {
        XCTAssertThrowsError(try LoadProfileUseCase(repository: InMemoryProfileRepository()).execute(id: UUID())) { error in
            XCTAssertEqual(error as? PositionError, .profileNotFound)
        }
    }

    func testListProfilesMostRecentFirst() throws {
        let repository = InMemoryProfileRepository([
            .sample(name: "Vieja", updatedAt: Date(timeIntervalSince1970: 1)),
            .sample(name: "Nueva", updatedAt: Date(timeIntervalSince1970: 2)),
        ])

        XCTAssertEqual(try ListProfilesUseCase(repository: repository).execute().map(\.name), ["Nueva", "Vieja"])
    }

    func testEvaluatePositionComparesWithTheProfileReference() {
        let profile = DrivingProfile.sample(reference: .cm(depth: 60))

        let evaluation = EvaluatePositionUseCase().execute(current: .cm(depth: 64), profile: profile)

        XCTAssertEqual(evaluation.adjustments, [.moveSeatForward(centimeters: 4)])
    }
}
