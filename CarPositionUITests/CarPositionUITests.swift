import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// El simulador no tiene cámara ni ARKit. Con `-uiTesting` la app usa una
/// base de datos vacía en memoria y una **cámara simulada** que "ve" siempre
/// la misma cabeza, así que una posición recién calibrada coincide consigo
/// misma.
final class CarPositionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    func testTheListStartsEmpty() {
        XCTAssertTrue(app.staticTexts["Aún no hay posiciones"].waitForExistence(timeout: 5))
    }

    func testCalibratingAndThenCheckingAPosition() {
        app.buttons["Nueva posición"].firstMatch.tap()

        let name = app.textFields["profileName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.clearAndType("Mi posición de prueba\n") // "\n" cierra el teclado.

        let calibrate = app.buttons["Calibrar"]
        XCTAssertTrue(calibrate.waitForExistence(timeout: 5))
        calibrate.tap()

        // Cuenta atrás (3 s) + medición: al terminar vuelve a la lista.
        let row = app.staticTexts["Mi posición de prueba"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))

        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["Todo en su sitio"].firstMatch.waitForExistence(timeout: 10))
    }

    func testDeletingAPosition() {
        app.buttons["Nueva posición"].firstMatch.tap()
        let name = app.textFields["profileName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.clearAndType("Para borrar\n")
        let calibrate = app.buttons["Calibrar"]
        XCTAssertTrue(calibrate.waitForExistence(timeout: 5))
        calibrate.tap()

        let row = app.staticTexts["Para borrar"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.swipeLeft()
        app.buttons["Delete"].firstMatch.tapIfExists(orElse: app.buttons["Eliminar"].firstMatch)

        XCTAssertTrue(app.staticTexts["Aún no hay posiciones"].waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    /// Borra el texto del campo y escribe otro.
    func clearAndType(_ text: String) {
        if let current = value as? String, !current.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        typeText(text)
    }

    /// Toca este botón o, si no existe (idioma del simulador), el otro.
    func tapIfExists(orElse other: XCUIElement) {
        if waitForExistence(timeout: 2) {
            tap()
        } else {
            other.tap()
        }
    }
}
