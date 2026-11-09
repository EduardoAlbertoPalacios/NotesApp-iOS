import XCTest

/// Pruebas de UI de "Mis notas" (spec 001). La app se lanza con `-UITesting`: almacén en
/// memoria y ajustes vacíos, así que siempre se siembran las 6 notas de ejemplo.
///
/// Fuera de alcance aquí:
/// - iPad (RF-5 a RF-7): el runtime instalado solo admite el simulador `iPhone Duo`.
/// - Ajustes y orden: están ocultos a accesibilidad (`accessibilityHidden`), no se tocan.
/// - RF-28 (las notas persisten al relanzar): `-UITesting` usa un almacén en memoria y sin
///   él la app usaría el almacén real del simulador; lo cubre DataTests.
@MainActor
final class NoteListUITests: XCTestCase {
    /// Copia de `NoteListAccessibilityID` (el target de UI no enlaza `Presentation`).
    private enum ID {
        static let counter = "noteList.counter"
        static let searchField = "noteList.searchField"
        static let filterAll = "noteList.filter.all"
        static let filterWork = "noteList.filter.work"
        static let filterPersonal = "noteList.filter.personal"
        static let card = "noteList.card"
        static let error = "noteList.error"
        static let retryButton = "noteList.retryButton"
        static let newNoteButton = "noteList.newNoteButton"
    }

    private enum LaunchArgument {
        static let uiTesting = "-UITesting"
        static let loadFailure = "-UITestingLoadFailure"
    }

    private let timeout: TimeInterval = 10
    private let counterText = "6 notas · un espacio para tus ideas"
    private let expectedTitles = [
        "Reunión de equipo",
        "La compra",
        "Ideas sueltas",
        "Escapada",
        "Para leer",
        "Una buena idea",
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Con notas

    func testGivenFreshLaunchWhenScreenAppearsThenShowsTitleAndCounter() {
        let app = launch()

        XCTAssertTrue(app.staticTexts["Mis notas"].waitForExistence(timeout: timeout))
        let counter = element(ID.counter, in: app)
        XCTAssertTrue(counter.waitForExistence(timeout: timeout))
        XCTAssertEqual(counter.label, counterText)
    }

    /// El orden se comprueba por posición en pantalla (RF-8: la nota *i* va a la columna
    /// *i mod 2*; RF-9: cada columna se apila de arriba abajo). El orden del árbol de
    /// accesibilidad no sirve: XCUITest lo devuelve ordenado por coordenada Y.
    func testGivenSampleNotesWhenScreenAppearsThenShowsSixCardsInFigmaOrder() {
        let app = launch()
        XCTAssertTrue(cards(in: app).firstMatch.waitForExistence(timeout: timeout))

        let frames = expectedTitles.map { card(titled: $0, in: app).frame }

        XCTAssertEqual(cards(in: app).count, expectedTitles.count)
        XCTAssertEqual(Set(cardTitles(in: app)), Set(expectedTitles))
        let leftX = frames[0].minX
        let rightX = frames[1].minX
        XCTAssertLessThan(leftX, rightX)
        for (index, frame) in frames.enumerated() {
            XCTAssertEqual(frame.minX, index.isMultiple(of: 2) ? leftX : rightX, accuracy: 1, expectedTitles[index])
            if index >= 2 {
                XCTAssertGreaterThan(frame.minY, frames[index - 2].maxY, expectedTitles[index])
            }
        }
        XCTAssertEqual(frames[0].minY, frames[1].minY, accuracy: 1)
    }

    func testGivenPinnedNoteWhenReadingItsCardThenLabelIncludesPinned() {
        let app = launch()

        let card = card(titled: "Reunión de equipo", in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("Fijada"), "Etiqueta: \(card.label)")
    }

    func testGivenChecklistNoteWhenReadingItsCardThenLabelIncludesTaskStatus() {
        let app = launch()

        let card = card(titled: "La compra", in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("Pan integral, completada"), "Etiqueta: \(card.label)")
        XCTAssertTrue(card.label.contains("Tomates, pendiente"), "Etiqueta: \(card.label)")
    }

    func testGivenFreshLaunchWhenScreenAppearsThenShowsStaticControls() {
        let app = launch()

        XCTAssertTrue(element(ID.counter, in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(element(ID.searchField, in: app).label, "Buscar en tus notas")
        XCTAssertEqual(element(ID.filterAll, in: app).label, "Todas")
        XCTAssertEqual(element(ID.filterWork, in: app).label, "Trabajo")
        XCTAssertEqual(element(ID.filterPersonal, in: app).label, "Personal")
        XCTAssertTrue(app.staticTexts["Última edición"].exists)
        XCTAssertEqual(element(ID.newNoteButton, in: app).label, "Nueva nota")
    }

    func testGivenStaticControlsWhenTappedThenScreenDoesNotChange() {
        let app = launch()
        XCTAssertTrue(element(ID.counter, in: app).waitForExistence(timeout: timeout))

        element(ID.searchField, in: app).tap()
        element(ID.filterWork, in: app).tap()
        element(ID.filterPersonal, in: app).tap()
        element(ID.newNoteButton, in: app).tap()
        card(titled: "Reunión de equipo", in: app).tap()

        XCTAssertEqual(app.keyboards.count, 0)
        XCTAssertEqual(element(ID.counter, in: app).label, counterText)
        XCTAssertEqual(cards(in: app).count, expectedTitles.count)
        XCTAssertEqual(Set(cardTitles(in: app)), Set(expectedTitles))
        XCTAssertTrue(element(ID.filterAll, in: app).isSelected)
        XCTAssertFalse(element(ID.filterWork, in: app).isSelected)
    }

    func testGivenNotesBelowTheFoldWhenSwipingUpThenLastNoteBecomesVisible() {
        let app = launch()
        let lastCard = card(titled: "Una buena idea", in: app)
        XCTAssertTrue(lastCard.waitForExistence(timeout: timeout))

        var swipes = 0
        while !isFullyVisible(lastCard, in: app), swipes < 5 {
            app.swipeUp()
            swipes += 1
        }

        XCTAssertTrue(isFullyVisible(lastCard, in: app), "Marco: \(lastCard.frame)")
        XCTAssertTrue(lastCard.isHittable)
    }

    // MARK: - Error de carga

    func testGivenUnavailableStorageWhenScreenAppearsThenShowsErrorAndRetry() {
        let app = launch(extraArguments: [LaunchArgument.loadFailure])

        XCTAssertTrue(element(ID.error, in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(element(ID.error, in: app).label, "No pudimos cargar tus notas.")
        XCTAssertEqual(app.buttons[ID.retryButton].label, "Reintentar")
        XCTAssertTrue(app.staticTexts["Mis notas"].exists)
        XCTAssertFalse(element(ID.counter, in: app).exists)
        XCTAssertEqual(cards(in: app).count, 0)
    }

    func testGivenUnavailableStorageWhenTappingRetryThenErrorRemains() {
        let app = launch(extraArguments: [LaunchArgument.loadFailure])
        let retry = app.buttons[ID.retryButton]
        XCTAssertTrue(retry.waitForExistence(timeout: timeout))

        retry.tap()

        XCTAssertTrue(element(ID.error, in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons[ID.retryButton].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Mis notas"].exists)
        XCTAssertFalse(element(ID.counter, in: app).exists)
        XCTAssertEqual(cards(in: app).count, 0)
    }

    // MARK: - Helpers

    private func launch(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // Idioma fijo: los textos de la pantalla solo existen en español.
        app.launchArguments = [LaunchArgument.uiTesting] + extraArguments
            + ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
        return app
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func cards(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: ID.card)
    }

    private func card(titled title: String, in app: XCUIApplication) -> XCUIElement {
        cards(in: app).matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    /// Título de cada tarjeta (el orden es el del árbol de accesibilidad, no el de la cuadrícula).
    private func cardTitles(in app: XCUIApplication) -> [String] {
        cards(in: app).allElementsBoundByIndex.map { card in
            expectedTitles.first { card.label.hasPrefix($0) } ?? card.label
        }
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        element.exists && app.windows.firstMatch.frame.contains(element.frame)
    }
}
