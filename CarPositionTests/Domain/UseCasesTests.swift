import XCTest
@testable import CarPosition

final class UseCasesTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_000)
    private let fixedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    func testCreateProfileTrimsAndSavesTheSeatWithoutHead() throws {
        let repository = InMemoryProfileRepository()
        let useCase = CreateProfileUseCase(repository: repository, now: { self.fixedDate }, makeID: { self.fixedID })

        let profile = try useCase.execute(name: "  Mi posición ", notes: " Volante 2 \n", seat: TestCar.seat)

        XCTAssertEqual(profile.name, "Mi posición")
        XCTAssertEqual(profile.notes, "Volante 2")
        XCTAssertEqual(profile.seat, TestCar.seat)
        XCTAssertNil(profile.head)
        XCTAssertEqual(profile.createdAt, fixedDate)
        XCTAssertEqual(repository.profiles[fixedID], profile)
    }

    func testCreateProfileRejectsAnEmptyName() {
        let repository = InMemoryProfileRepository()

        XCTAssertThrowsError(try CreateProfileUseCase(repository: repository).execute(name: "   ", notes: "", seat: TestCar.seat)) { error in
            XCTAssertEqual(error as? PositionError, .invalidName)
        }
        XCTAssertTrue(repository.profiles.isEmpty)
    }

    func testUpdateSeatKeepsNameNotesAndHead() throws {
        let original = DrivingProfile.sample(name: "Yo", notes: "Espejos", head: .cm(depth: 60))
        let repository = InMemoryProfileRepository([original])
        var newSeat = TestCar.seat
        newSeat.cushionFront.x += 0.03

        let updated = try UpdateSeatUseCase(repository: repository, now: { self.fixedDate })
            .execute(id: original.id, seat: newSeat)

        XCTAssertEqual(updated.seat, newSeat)
        XCTAssertEqual(updated.name, "Yo")
        XCTAssertEqual(updated.head, .cm(depth: 60))
        XCTAssertEqual(updated.updatedAt, fixedDate)
        XCTAssertEqual(repository.profiles[original.id], updated)
    }

    func testUpdateHeadReferenceKeepsTheSeat() throws {
        let original = DrivingProfile.sample(head: nil)
        let repository = InMemoryProfileRepository([original])

        let updated = try UpdateHeadReferenceUseCase(repository: repository, now: { self.fixedDate })
            .execute(id: original.id, reference: .cm(depth: 65))

        XCTAssertEqual(updated.head, .cm(depth: 65))
        XCTAssertEqual(updated.seat, TestCar.seat)
        XCTAssertEqual(repository.profiles[original.id], updated)
    }

    func testUpdatesOfAMissingProfileFail() {
        let repository = InMemoryProfileRepository()

        XCTAssertThrowsError(try UpdateHeadReferenceUseCase(repository: repository).execute(id: UUID(), reference: .cm())) { error in
            XCTAssertEqual(error as? PositionError, .profileNotFound)
        }
        XCTAssertThrowsError(try UpdateSeatUseCase(repository: repository).execute(id: UUID(), seat: TestCar.seat)) { error in
            XCTAssertEqual(error as? PositionError, .profileNotFound)
        }
    }

    func testUpdateNotesKeepsTheMeasurements() throws {
        let original = DrivingProfile.sample(head: .cm(depth: 61))
        let repository = InMemoryProfileRepository([original])

        let updated = try UpdateNotesUseCase(repository: repository)
            .execute(id: original.id, name: "Otra", notes: "Volante abajo")

        XCTAssertEqual(updated.name, "Otra")
        XCTAssertEqual(updated.notes, "Volante abajo")
        XCTAssertEqual(updated.seat, original.seat)
        XCTAssertEqual(updated.head, .cm(depth: 61))
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

    func testEvaluateHeadComparesWithTheHeadReference() {
        let profile = DrivingProfile.sample(head: .cm(depth: 60))

        let evaluation = EvaluateHeadUseCase().execute(current: .cm(depth: 64), profile: profile)

        XCTAssertEqual(evaluation?.adjustments, [.moveSeatForward(centimeters: 4)])
    }

    func testEvaluateHeadWithoutReferenceGivesNothing() {
        XCTAssertNil(EvaluateHeadUseCase().execute(current: .cm(), profile: .sample(head: nil)))
    }

    func testCheckSeatComparesCushionAndBackrestWithTheProfile() {
        let profile = DrivingProfile.sample()
        let useCase = CheckSeatUseCase()
        let seat = TestCar.seat

        var cushion = seat.cushionFront
        cushion.x -= 0.03
        XCTAssertEqual(useCase.cushion(cushion, profile: profile).adjustments, [.moveSeatForward(centimeters: 3)])
        XCTAssertTrue(useCase.backrest(lower: seat.backrestLower, upper: seat.backrestUpper, profile: profile).isMatch)
    }
}
