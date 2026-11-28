import SwiftData
import XCTest
@testable import CarPosition

/// La base de datos real (SwiftData), en archivos temporales.
///
/// Las pruebas de interfaz usan una base de datos en memoria; estas son las
/// que comprueban lo que solo pasa en disco: guardar y leer, migrar desde la
/// primera versión de la app y recuperarse de un archivo que no se puede abrir.
@MainActor
final class SwiftDataProfileRepositoryTests: XCTestCase {
    private var folder: URL!

    private var storeURL: URL { folder.appending(path: "default.store") }

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    func testSavesAndReadsAProfileWithAndWithoutHead() throws {
        let repository = SwiftDataProfileRepository(container: try SwiftDataProfileRepository.makeContainer(at: storeURL))
        let withoutHead = DrivingProfile.sample(name: "Sin cara", head: nil, updatedAt: Date(timeIntervalSince1970: 1))
        let withHead = DrivingProfile.sample(name: "Con cara", head: .cm(depth: 62), updatedAt: Date(timeIntervalSince1970: 2))

        try repository.save(withoutHead)
        try repository.save(withHead)

        XCTAssertEqual(try repository.listProfiles(), [withHead, withoutHead])
        XCTAssertEqual(try repository.findProfile(id: withoutHead.id), withoutHead)
    }

    func testOpensADatabaseFromTheFirstVersionOfTheApp() throws {
        // Base de datos creada por la primera versión (solo cámara frontal).
        try autoreleasepool {
            let old = try ModelContainer(
                for: FirstVersion.ProfileRecord.self,
                configurations: ModelConfiguration(url: storeURL)
            )
            let context = ModelContext(old)
            context.insert(FirstVersion.ProfileRecord(name: "De antes"))
            try context.save()
        }

        let (container, setAsideBecause) = try SwiftDataProfileRepository.openRecovering(at: storeURL)
        let repository = SwiftDataProfileRepository(container: container)

        XCTAssertNil(setAsideBecause, "La migración debería ser automática: \(String(describing: setAsideBecause))")
        // La posición vieja no tiene asiento: se ignora.
        XCTAssertEqual(try repository.listProfiles(), [])
        // Y se pueden guardar posiciones nuevas.
        try repository.save(.sample(name: "Nueva"))
        XCTAssertEqual(try repository.listProfiles().map(\.name), ["Nueva"])
    }

    func testAFileThatCannotBeOpenedIsSetAsideInsteadOfClosingTheApp() throws {
        try Data("esto no es una base de datos".utf8).write(to: storeURL)

        let (container, setAsideBecause) = try SwiftDataProfileRepository.openRecovering(at: storeURL)
        let repository = SwiftDataProfileRepository(container: container)

        XCTAssertNotNil(setAsideBecause)
        XCTAssertEqual(try repository.listProfiles(), [])
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("default.store.apartado-") }, "\(files)")
    }
}

/// El esquema de la primera versión de la app (en `main`, solo cámara
/// frontal), para comprobar que la versión actual sabe abrirlo.
enum FirstVersion {
    @Model
    final class ProfileRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var notes: String
        var createdAt: Date
        var updatedAt: Date

        var depth: Double
        var height: Double
        var lateral: Double
        var gravityX: Double
        var gravityY: Double
        var gravityZ: Double
        var sampleCount: Int

        init(name: String) {
            id = UUID()
            self.name = name
            notes = ""
            createdAt = .now
            updatedAt = .now
            depth = 0.6
            height = 0.1
            lateral = 0
            gravityX = 0
            gravityY = -1
            gravityZ = 0
            sampleCount = 90
        }
    }
}
