import XCTest

/// Pruebas de interfaz: lanzan la app real en el simulador y la tocan.
///
/// El simulador no tiene cámaras ni ARKit. Con `-uiTesting` la app usa una
/// base de datos vacía en memoria y **cámaras simuladas**: la trasera "apunta"
/// siempre al punto que se pide de un asiento imaginario, y la frontal "ve"
/// siempre la misma cabeza. Así, una posición recién guardada coincide
/// consigo misma.
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

    func testSavingASeatAndFollowingTheARGuide() {
        saveSeat(named: "Asiento de prueba")

        app.staticTexts["Asiento de prueba"].tap()
        tap(app.buttons["seatCheck"])

        // Referencia: los dos extremos del umbral.
        tapMark()
        tapMark()
        assertExists("Cojín en su sitio", timeout: 10)

        tap(app.buttons["Siguiente: respaldo"])
        tapMark()
        assertExists("Respaldo en su sitio", timeout: 10)

        tap(app.buttons["Terminar"])
        assertExists("Resumen")
    }

    func testCalibratingAndCheckingWithTheFrontCamera() {
        saveSeat(named: "Con mi cara")
        app.staticTexts["Con mi cara"].tap()

        tap(app.buttons["headCalibration"])
        tap(app.buttons["Calibrar"])

        // Cuenta atrás (3 s) + medición: al terminar vuelve a la ficha.
        let check = app.buttons["headCheck"]
        XCTAssertTrue(check.waitForExistence(timeout: 20))
        check.tap()
        assertExists("Todo en su sitio", timeout: 10)
    }

    // MARK: - Ayudantes

    /// Crea una posición marcando los cinco puntos del asiento simulado.
    private func saveSeat(named name: String) {
        app.buttons["Nueva posición"].firstMatch.tap()
        for _ in 0..<5 {
            tapMark()
        }
        let field = app.textFields["profileName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.clearAndType(name + "\n") // "\n" cierra el teclado.
        tap(app.buttons["Guardar posición"])
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 10))
    }

    /// Espera a que "Marcar" se active (la mira encontró el punto) y lo toca.
    private func tapMark() {
        let mark = app.buttons["Marcar"]
        XCTAssertTrue(mark.waitForExistence(timeout: 5))
        let enabled = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: mark)
        wait(for: [enabled], timeout: 5)
        mark.tap()
    }

    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        element.tap()
    }

    private func assertExists(_ text: String, timeout: TimeInterval = 5) {
        XCTAssertTrue(
            app.descendants(matching: .any)[text].firstMatch.waitForExistence(timeout: timeout),
            "No apareció «\(text)»"
        )
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
}
