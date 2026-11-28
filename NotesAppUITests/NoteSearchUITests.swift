import XCTest

/// Pruebas de UI del buscador de "Mis notas" (spec 004). La app se lanza con `-UITesting`: almacén en
/// memoria con las 6 notas de ejemplo; solo "Reunión de equipo" está fijada y "La compra" es una
/// lista de tareas ("Tomates", "Leche de avena", "Pan integral", "Café").
///
/// Cada prueba comprueba al empezar que el buscador está vacío: el texto vive en `@SceneStorage` y no
/// debe pasar de una prueba a la siguiente (plan 004, Riesgos).
///
/// Fuera de alcance aquí:
/// - RF-30 y RF-31 (restaurar o no la búsqueda tras un cierre): demo manual. Una prueba que pasaba la
///   app a segundo plano y la relanzaba fallaba a veces: iOS no siempre guarda `@SceneStorage` antes
///   de que XCUITest termine la app.
/// - Tecla "Buscar" del teclado (RF-23), anuncios de VoiceOver (RF-40 a RF-44) y texto grande
///   (RF-45): pruebas unitarias, previews y demo manual.
/// - iPad: el runtime instalado solo admite el simulador `iPhone Duo`.
@MainActor
final class NoteSearchUITests: XCTestCase {
    /// Copia de `NoteListAccessibilityID` y `NoteEditorAccessibilityID` (el target de UI no
    /// enlaza `Presentation`).
    private enum ID {
        static let listCounter = "noteList.counter"
        static let listCard = "noteList.card"
        static let listError = "noteList.error"
        static let searchField = "noteList.searchField"
        static let searchClearButton = "noteList.searchClearButton"
        static let noResults = "noteList.noResults"
        static let emptyState = "noteList.emptyState"
        static let screen = "noteList.screen"
        static let filterAll = "noteList.filter.all"
        static let filterWork = "noteList.filter.work"
        static let filterPersonal = "noteList.filter.personal"
        static let undoBanner = "noteList.undoBanner"
        static let undoButton = "noteList.undoButton"
        static let backButton = "noteEditor.backButton"
        static let moreButton = "noteEditor.moreButton"
        static let deleteMenuItem = "noteEditor.menu.delete"
        static let titleField = "noteEditor.titleField"
        static let saveStatus = "noteEditor.saveStatus"
    }

    private enum LaunchArgument {
        static let uiTesting = "-UITesting"
        static let loadFailure = "-UITestingLoadFailure"
    }

    private let timeout: TimeInterval = 10
    private let sampleNoteCount = 6
    private let usualCounter = "6 notas · un espacio para tus ideas"
    private let searchPlaceholder = "Buscar en tus notas"
    private let sampleTitles = [
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

    // MARK: - Búsqueda al escribir y coincidencia flexible (RF-1 a RF-15, RF-39)

    func testGivenSampleNotesWhenTypingWithoutAccentThenShowsOnlyMeetingAndOneResult() throws {
        let app = launchWithEmptySearch()

        search("reunion", in: app)

        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let screen = try app.snapshot()
        let cards = findAll(ID.listCard, in: screen)
        XCTAssertEqual(cards.count, 1, "Tarjetas: \(cards.map(\.label))")
        XCTAssertTrue(cards.first?.label.hasPrefix("Reunión de equipo") == true, "Tarjetas: \(cards.map(\.label))")
        XCTAssertNil(find(ID.noResults, in: screen))
        // Los filtros siguen igual que sin búsqueda (RF-39).
        XCTAssertEqual(find(ID.filterAll, in: screen)?.label, "Todas")
        XCTAssertEqual(find(ID.filterAll, in: screen)?.isSelected, true)
        XCTAssertEqual(find(ID.filterWork, in: screen)?.isSelected, false)
        XCTAssertEqual(find(ID.filterPersonal, in: screen)?.isSelected, false)
    }

    func testGivenSampleNotesWhenTypingUppercaseWordsInOtherOrderThenShowsSameResult() throws {
        let app = launchWithEmptySearch()

        search("EQUIPO reunión", in: app)

        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let cards = findAll(ID.listCard, in: try app.snapshot())
        XCTAssertEqual(cards.count, 1, "Tarjetas: \(cards.map(\.label))")
        XCTAssertTrue(cards.first?.label.hasPrefix("Reunión de equipo") == true, "Tarjetas: \(cards.map(\.label))")
    }

    func testGivenChecklistNoteWhenTypingTextOfOneOfItsTasksThenShowsShoppingList() throws {
        let app = launchWithEmptySearch()

        search("avena", in: app)

        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let cards = findAll(ID.listCard, in: try app.snapshot())
        XCTAssertEqual(cards.count, 1, "Tarjetas: \(cards.map(\.label))")
        XCTAssertTrue(cards.first?.label.hasPrefix("La compra") == true, "Tarjetas: \(cards.map(\.label))")
    }

    // MARK: - Sin resultados (RF-16, RF-18, RF-19)

    func testGivenSampleNotesWhenTypingTextWithoutMatchesThenShowsNoResultsMessageAndZeroResults() throws {
        let app = launchWithEmptySearch()

        search("proveedores", in: app)

        let noResults = element(ID.noResults, in: app)
        XCTAssertTrue(noResults.waitForExistence(timeout: timeout), app.debugDescription)
        let screen = try app.snapshot()
        XCTAssertEqual(find(ID.noResults, in: screen)?.label, "No hay notas que coincidan con «proveedores»")
        XCTAssertEqual(find(ID.listCounter, in: screen)?.label, "0 resultados")
        XCTAssertNil(find(ID.emptyState, in: screen))
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, 0)
    }

    // MARK: - Limpiar la búsqueda (RF-17, RF-20 a RF-22)

    func testGivenActiveSearchWhenTappingClearButtonThenShowsAllNotesAndUsualCounter() throws {
        let app = launchWithEmptySearch()
        search("reunion", in: app)
        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let clearButton = element(ID.searchClearButton, in: app)
        XCTAssertTrue(clearButton.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(clearButton.label, "Borrar búsqueda")

        clearButton.tap()

        XCTAssertTrue(waitForLabel(usualCounter, of: element(ID.listCounter, in: app)), app.debugDescription)
        let screen = try app.snapshot()
        let cards = findAll(ID.listCard, in: screen)
        XCTAssertEqual(cards.count, sampleNoteCount)
        for title in sampleTitles {
            XCTAssertTrue(cards.contains { $0.label.hasPrefix(title) }, title)
        }
        XCTAssertNil(find(ID.searchClearButton, in: screen))
        let value = searchValue(in: screen)
        XCTAssertTrue(isEmptySearch(value), "Buscador: \(String(describing: value))")
    }

    // MARK: - Conservar la búsqueda (RF-25, RF-26, RF-28, RF-29)

    func testGivenActiveSearchWhenOpeningResultAndGoingBackThenSearchAndResultsRemain() throws {
        let app = launchWithEmptySearch()
        search("reunion", in: app)
        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)

        openNote(titled: "Reunión de equipo", in: app)
        goBackToList(in: app)

        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let screen = try app.snapshot()
        XCTAssertEqual(searchValue(in: screen), "reunion")
        let cards = findAll(ID.listCard, in: screen)
        XCTAssertEqual(cards.count, 1, "Tarjetas: \(cards.map(\.label))")
        XCTAssertTrue(cards.first?.label.hasPrefix("Reunión de equipo") == true, "Tarjetas: \(cards.map(\.label))")
        XCTAssertNotNil(find(ID.searchClearButton, in: screen))
    }

    func testGivenActiveSearchWhenEditingResultSoItNoLongerMatchesThenItDisappearsOnReturn() throws {
        let app = launchWithEmptySearch()
        search("reunion", in: app)
        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        openNote(titled: "Reunión de equipo", in: app)
        let titleField = element(ID.titleField, in: app)

        clear(titleField)
        titleField.typeText("Sprint")
        XCTAssertEqual(titleField.value as? String, "Sprint")
        XCTAssertTrue(element(ID.saveStatus, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        goBackToList(in: app)

        XCTAssertTrue(waitForLabel("0 resultados", of: element(ID.listCounter, in: app)), app.debugDescription)
        let screen = try app.snapshot()
        XCTAssertEqual(searchValue(in: screen), "reunion")
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, 0)
        XCTAssertEqual(find(ID.noResults, in: screen)?.label, "No hay notas que coincidan con «reunion»")
    }

    func testGivenActiveSearchWhenDeletingResultAndTappingUndoThenItReturnsToResults() throws {
        let app = launchWithEmptySearch()
        search("reunion", in: app)
        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        openNote(titled: "Reunión de equipo", in: app)

        tapDeleteInMoreMenu(in: app)
        // El aviso caduca a los 5 s y cada consulta de XCUITest tarda ~1 s: se espera el botón
        // "Deshacer" y se toca enseguida; lo intermedio se comprueba en una sola instantánea.
        let undoButton = element(ID.undoButton, in: app)
        XCTAssertTrue(undoButton.waitForExistence(timeout: timeout), app.debugDescription)
        let afterDelete = try app.snapshot()
        undoButton.tap()

        XCTAssertEqual(searchValue(in: afterDelete), "reunion")
        XCTAssertEqual(find(ID.listCounter, in: afterDelete)?.label, "0 resultados")
        XCTAssertEqual(findAll(ID.listCard, in: afterDelete).count, 0)
        XCTAssertTrue(element(ID.undoBanner, in: app).waitForNonExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(waitForLabel("1 resultado", of: element(ID.listCounter, in: app)), app.debugDescription)
        let restored = try app.snapshot()
        XCTAssertEqual(searchValue(in: restored), "reunion")
        let cards = findAll(ID.listCard, in: restored)
        XCTAssertEqual(cards.count, 1, "Tarjetas: \(cards.map(\.label))")
        XCTAssertTrue(cards.first?.label.hasPrefix("Reunión de equipo") == true, "Tarjetas: \(cards.map(\.label))")
        XCTAssertNil(find(ID.noResults, in: restored))
    }

    // MARK: - Teclado (RF-24)

    func testGivenOpenKeyboardWhenScrollingResultsThenKeyboardHidesAndSearchRemains() throws {
        let app = launchWithEmptySearch()
        search("a", in: app)
        XCTAssertTrue(waitForLabel("6 resultados", of: element(ID.listCounter, in: app)), app.debugDescription)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: timeout), "El teclado no llegó a abrirse.")

        // Arrastre dentro de la zona visible sobre el teclado (el centro de la cuadrícula puede quedar
        // debajo de él y el gesto caería en las teclas).
        let screenArea = element(ID.screen, in: app)
        let searchField = element(ID.searchField, in: app)
        let fieldFrameBefore = searchField.frame
        let start = screenArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        let end = screenArea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(
            app.keyboards.firstMatch.waitForNonExistence(timeout: timeout),
            "El teclado sigue abierto tras desplazar. Buscador antes: \(fieldFrameBefore), después: "
                + "\(searchField.frame), foco: \(searchField.hasKeyboardFocusDescription)\n\(app.debugDescription)"
        )
        XCTAssertEqual(app.keyboards.count, 0)
        let screen = try app.snapshot()
        XCTAssertEqual(searchValue(in: screen), "a")
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, sampleNoteCount)
    }

    // MARK: - Buscador deshabilitado (RF-36)

    func testGivenUnavailableStorageWhenScreenAppearsThenSearchFieldIsDisabled() {
        let app = launch(extraArguments: [LaunchArgument.loadFailure])
        XCTAssertTrue(element(ID.listError, in: app).waitForExistence(timeout: timeout), app.debugDescription)

        let field = element(ID.searchField, in: app)

        XCTAssertTrue(field.exists, app.debugDescription)
        XCTAssertFalse(field.isEnabled)
        XCTAssertFalse(element(ID.searchClearButton, in: app).exists)
    }

    // MARK: - Helpers

    private func launch(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        // Idioma fijo: los textos de la app solo existen en español.
        app.launchArguments = [LaunchArgument.uiTesting] + extraArguments
            + ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
        return app
    }

    private func launchWithEmptySearch(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = launch()
        assertSearchIsEmpty(in: app, file: file, line: line)
        return app
    }

    private func assertSearchIsEmpty(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            waitForLabel(usualCounter, of: element(ID.listCounter, in: app)),
            "El contador no es el habitual al lanzar.\n\(app.debugDescription)",
            file: file, line: line
        )
        guard let screen = try? app.snapshot() else {
            XCTFail("No se pudo leer la pantalla.", file: file, line: line)
            return
        }
        let value = searchValue(in: screen)
        XCTAssertTrue(
            isEmptySearch(value), "El buscador empieza con texto: \(String(describing: value))", file: file, line: line
        )
        XCTAssertNil(
            find(ID.searchClearButton, in: screen), "El botón de borrar está visible al lanzar.", file: file, line: line
        )
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, sampleNoteCount, file: file, line: line)
    }

    /// Un `TextField` vacío expone como valor su texto de ayuda (o nada).
    private func isEmptySearch(_ value: String?) -> Bool {
        value == nil || value == "" || value == searchPlaceholder
    }

    private func searchValue(in snapshot: any XCUIElementSnapshot) -> String? {
        find(ID.searchField, in: snapshot)?.value as? String
    }

    private func search(_ text: String, in app: XCUIApplication) {
        let field = element(ID.searchField, in: app)
        XCTAssertTrue(waitUntilHittable(field), app.debugDescription)
        field.tap()
        field.typeText(text)
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func card(titled title: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: ID.listCard)
            .matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    private func openNote(titled title: String, in app: XCUIApplication) {
        let card = card(titled: title, in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout), app.debugDescription)
        card.tap()
        XCTAssertTrue(element(ID.titleField, in: app).waitForExistence(timeout: timeout), app.debugDescription)
    }

    private func goBackToList(in app: XCUIApplication) {
        element(ID.backButton, in: app).tap()
        XCTAssertTrue(element(ID.listCounter, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(element(ID.titleField, in: app).waitForNonExistence(timeout: timeout), app.debugDescription)
    }

    /// Abre el menú ⋯ y elige "Eliminar nota" tocando el elemento del menú (como en
    /// `NoteDeletionUITests`): se espera a que la opción sea tocable y se reintenta una vez.
    private func tapDeleteInMoreMenu(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let moreButton = element(ID.moreButton, in: app)
        let deleteItem = element(ID.deleteMenuItem, in: app)
        let maxAttempts = 2
        for attempt in 1...maxAttempts {
            XCTAssertTrue(
                waitUntilHittable(moreButton),
                "El botón ⋯ no es tocable (intento \(attempt)).\n\(app.debugDescription)",
                file: file, line: line
            )
            moreButton.tap()
            if waitUntilHittable(deleteItem) {
                deleteItem.tap()
                return
            }
            if deleteItem.exists {
                app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()
                _ = deleteItem.waitForNonExistence(timeout: timeout)
            }
        }
        XCTFail(
            "La opción \"Eliminar nota\" del menú ⋯ no apareció tocable tras \(maxAttempts) intentos.\n"
                + app.debugDescription,
            file: file, line: line
        )
    }

    /// Borra todo el texto: pone el cursor al final y borra carácter a carácter (como en `NoteEditorUITests`).
    private func clear(_ field: XCUIElement) {
        let length = (field.value as? String)?.count ?? 0
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length + 2))
    }

    /// Espera a que el elemento exista y sea tocable (`isHittable`), sin `sleep`.
    private func waitUntilHittable(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Espera a que el elemento exista con esa etiqueta, sin `sleep`.
    private func waitForLabel(_ label: String, of element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    // MARK: - Instantáneas (una sola consulta a la app)

    private func findAll(_ identifier: String, in snapshot: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        let own: [any XCUIElementSnapshot] = snapshot.identifier == identifier ? [snapshot] : []
        return own + snapshot.children.flatMap { findAll(identifier, in: $0) }
    }

    private func find(_ identifier: String, in snapshot: any XCUIElementSnapshot) -> (any XCUIElementSnapshot)? {
        findAll(identifier, in: snapshot).first
    }
}

extension XCUIElement {
    /// Para los mensajes de fallo: si el elemento tiene el foco del teclado.
    fileprivate var hasKeyboardFocusDescription: String {
        (value(forKey: "hasKeyboardFocus") as? Bool).map(String.init(describing:)) ?? "desconocido"
    }
}
