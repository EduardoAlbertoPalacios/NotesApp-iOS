import XCTest

/// Pruebas de UI del editor (spec 002): se abre desde la lista con "Nueva nota" (RF-1) o al tocar
/// una tarjeta (RF-4). La app se lanza con `-UITesting`: almacén en memoria con las 6 notas de
/// ejemplo, todas con la misma fecha; solo "Reunión de equipo" está fijada.
///
/// El guardado automático usa el reloj real (1 s sin cambios): se espera con `waitForExistence`.
///
/// Fuera de alcance aquí:
/// - Persistencia al relanzar (RF-31): `-UITesting` usa un almacén en memoria y sin él la app
///   usaría el almacén real del simulador; lo cubre DataTests.
/// - iPad: el runtime instalado solo admite el simulador `iPhone Duo`.
@MainActor
final class NoteEditorUITests: XCTestCase {
    /// Copia de `NoteListAccessibilityID` y `NoteEditorAccessibilityID` (el target de UI no
    /// enlaza `Presentation`).
    private enum ID {
        static let listCounter = "noteList.counter"
        static let listCard = "noteList.card"
        static let listError = "noteList.error"
        static let newNoteButton = "noteList.newNoteButton"
        static let backButton = "noteEditor.backButton"
        static let pinButton = "noteEditor.pinButton"
        static let shareButton = "noteEditor.shareButton"
        static let moreButton = "noteEditor.moreButton"
        static let headerCategory = "noteEditor.header.category"
        static let titleField = "noteEditor.titleField"
        static let saveStatus = "noteEditor.saveStatus"
        static let saveError = "noteEditor.saveError"
        static let categoryWork = "noteEditor.category.work"
        static let toolbar = [
            "noteEditor.toolbar.format",
            "noteEditor.toolbar.checklist",
            "noteEditor.toolbar.image",
            "noteEditor.toolbar.undo",
            "noteEditor.toolbar.color",
        ]

        static func textBlock(_ index: Int) -> String { "noteEditor.textBlock.\(index)" }
        static func task(_ index: Int) -> String { "noteEditor.task.\(index)" }
    }

    private enum LaunchArgument {
        static let uiTesting = "-UITesting"
        static let loadFailure = "-UITestingLoadFailure"
    }

    private let timeout: TimeInterval = 10
    private let sampleNoteCount = 6
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

    // MARK: - Abrir y volver

    func testGivenNoteListWhenTappingNewNoteThenOpensEmptyEditorAndBackReturnsToList() {
        let app = launch()

        openNewNote(in: app)

        let titleField = element(ID.titleField, in: app)
        XCTAssertEqual(titleField.placeholderValue, "Título")
        XCTAssertEqual(titleField.value as? String, "")

        goBackToList(in: app)

        XCTAssertFalse(element(ID.titleField, in: app).exists)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount)
    }

    func testGivenNoteListWhenTappingCardThenOpensEditorWithItsTitle() {
        let app = launch()

        openNote(titled: "Reunión de equipo", in: app)

        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "Reunión de equipo")
    }

    func testGivenNewNoteWhenEditorAppearsThenShowsTitleAndContentPlaceholders() {
        let app = launch()

        openNewNote(in: app)

        XCTAssertEqual(element(ID.titleField, in: app).placeholderValue, "Título")
        let content = element(ID.textBlock(0), in: app)
        XCTAssertTrue(content.exists)
        XCTAssertEqual(content.placeholderValue, "Escribir nota…")
        XCTAssertEqual(content.value as? String, "")
    }

    // MARK: - Crear

    func testGivenNewNoteWithTitleAndContentWhenGoingBackThenAppearsFirstAmongUnpinnedAndCounterUpdates() {
        let app = launch()
        openNewNote(in: app)

        type("Lista de viaje", into: element(ID.titleField, in: app))
        type("Pasaporte y cargador", into: element(ID.textBlock(0), in: app))
        XCTAssertTrue(element(ID.saveStatus, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(element(ID.saveStatus, in: app).label, "Todos los cambios guardados")
        goBackToList(in: app)

        XCTAssertEqual(element(ID.listCounter, in: app).label, "7 notas · un espacio para tus ideas")
        XCTAssertEqual(cards(in: app).count, sampleNoteCount + 1)
        let newCard = card(titled: "Lista de viaje", in: app)
        XCTAssertTrue(newCard.waitForExistence(timeout: timeout))
        XCTAssertTrue(newCard.label.contains("Pasaporte y cargador"), "Etiqueta: \(newCard.label)")
        XCTAssertFalse(newCard.label.contains("Fijada"), "Etiqueta: \(newCard.label)")
        // Posición 1 de la cuadrícula (RF-8 de la spec 001): arriba de la segunda columna,
        // justo después de la única fijada, que sigue arriba a la izquierda.
        let pinned = card(titled: "Reunión de equipo", in: app).frame
        XCTAssertGreaterThan(newCard.frame.minX, pinned.maxX)
        XCTAssertEqual(newCard.frame.minY, pinned.minY, accuracy: 1)
    }

    func testGivenNewNoteWithOnlyContentWhenGoingBackThenCardShowsUntitled() {
        let app = launch()
        openNewNote(in: app)

        type("Solo contenido", into: element(ID.textBlock(0), in: app))
        goBackToList(in: app)

        let untitled = card(titled: "Sin título", in: app)
        XCTAssertTrue(untitled.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(untitled.label.contains("Solo contenido"), "Etiqueta: \(untitled.label)")
        XCTAssertEqual(cards(in: app).count, sampleNoteCount + 1)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "7 notas · un espacio para tus ideas")
    }

    func testGivenNewNoteWhenGoingBackWithoutWritingThenGridIsUnchanged() {
        let app = launch()

        openNewNote(in: app)
        goBackToList(in: app)

        assertSampleNotesOnly(in: app)
    }

    func testGivenNewNoteWithOnlyCategoryOrPinWhenGoingBackThenGridIsUnchanged() {
        let app = launch()

        openNewNote(in: app)
        element(ID.categoryWork, in: app).tap()
        XCTAssertTrue(element(ID.headerCategory, in: app).waitForExistence(timeout: timeout))
        goBackToList(in: app)
        assertSampleNotesOnly(in: app)

        openNewNote(in: app)
        element(ID.pinButton, in: app).tap()
        XCTAssertEqual(element(ID.pinButton, in: app).value as? String, "Fijada")
        goBackToList(in: app)
        assertSampleNotesOnly(in: app)
    }

    // MARK: - Editar

    func testGivenUnpinnedNoteWhenPinningAndChoosingWorkThenHeaderShowsCategoryAndCardJoinsPinned() {
        let app = launch()
        openNote(titled: "Ideas sueltas", in: app)
        XCTAssertFalse(element(ID.headerCategory, in: app).exists)

        element(ID.pinButton, in: app).tap()
        element(ID.categoryWork, in: app).tap()

        let header = element(ID.headerCategory, in: app)
        XCTAssertTrue(header.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(header.label, "Trabajo")
        XCTAssertEqual(element(ID.pinButton, in: app).value as? String, "Fijada")
        XCTAssertTrue(element(ID.categoryWork, in: app).isSelected)
        goBackToList(in: app)

        let edited = card(titled: "Ideas sueltas", in: app)
        XCTAssertTrue(edited.waitForExistence(timeout: timeout))
        XCTAssertTrue(edited.label.contains("Fijada"), "Etiqueta: \(edited.label)")
        // Las dos fijadas ocupan la primera fila; la recién editada va primero (arriba a la izquierda).
        let other = card(titled: "Reunión de equipo", in: app).frame
        XCTAssertEqual(edited.frame.minY, other.minY, accuracy: 1)
        XCTAssertLessThan(edited.frame.maxX, other.minX)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount)
    }

    func testGivenExistingNoteWhenGoingBackWithoutChangesThenGridKeepsSamePositions() {
        let app = launch()
        XCTAssertTrue(cards(in: app).firstMatch.waitForExistence(timeout: timeout))
        let before = cardFrames(in: app)

        openNote(titled: "Ideas sueltas", in: app)
        goBackToList(in: app)

        XCTAssertEqual(cardFrames(in: app), before)
    }

    func testGivenChecklistNoteWhenOpenedThenShowsTasksAndTappingOneDoesNotChangeIt() {
        let app = launch()
        openNote(titled: "La compra", in: app)

        let expected = [
            ("Tomates", "pendiente"),
            ("Leche de avena", "pendiente"),
            ("Pan integral", "completada"),
            ("Café", "pendiente"),
        ]
        for (index, (text, status)) in expected.enumerated() {
            let task = element(ID.task(index), in: app)
            XCTAssertTrue(task.exists, "Tarea \(index)")
            XCTAssertEqual(task.label, text)
            XCTAssertEqual(task.value as? String, status, text)
        }

        element(ID.task(0), in: app).tap()
        element(ID.task(2), in: app).tap()

        XCTAssertEqual(element(ID.task(0), in: app).value as? String, "pendiente")
        XCTAssertEqual(element(ID.task(2), in: app).value as? String, "completada")
        goBackToList(in: app)
        let shopping = card(titled: "La compra", in: app)
        XCTAssertTrue(shopping.label.contains("Tomates, pendiente"), "Etiqueta: \(shopping.label)")
        XCTAssertTrue(shopping.label.contains("Pan integral, completada"), "Etiqueta: \(shopping.label)")
    }

    /// XCUITest tarda más de 1 s entre acciones, así que el título vacío se guarda antes de vaciar
    /// el contenido. La spec 002 (casos límite) lo prevé: la última versión guardada es entonces
    /// "Sin título" con el contenido anterior. La prueba espera ese guardado de forma explícita y
    /// comprueba que el estado vacío no se guarda (RF-36, RF-37).
    func testGivenExistingNoteWhenClearingTitleAndContentThenCardKeepsLastSavedText() {
        let app = launch()
        openNote(titled: "Ideas sueltas", in: app)
        let saveStatus = element(ID.saveStatus, in: app)

        clear(element(ID.titleField, in: app))
        XCTAssertTrue(saveStatus.waitForExistence(timeout: timeout), app.debugDescription)
        clear(element(ID.textBlock(0), in: app))
        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "")
        XCTAssertEqual(element(ID.textBlock(0), in: app).value as? String, "")
        goBackToList(in: app)

        let kept = card(titled: "Sin título", in: app)
        XCTAssertTrue(kept.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(kept.label.contains("Un café, una libreta y tiempo para crear."), "Etiqueta: \(kept.label)")
        XCTAssertEqual(cards(in: app).count, sampleNoteCount)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "6 notas · un espacio para tus ideas")
    }

    func testGivenExistingNoteWhenTappingStaticControlsThenEditorDoesNotChange() {
        let app = launch()
        openNote(titled: "Ideas sueltas", in: app)

        for identifier in [ID.shareButton, ID.moreButton] + ID.toolbar {
            let control = element(identifier, in: app)
            XCTAssertTrue(control.exists, identifier)
            control.tap()
        }

        XCTAssertTrue(element(ID.titleField, in: app).exists)
        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "Ideas sueltas")
        XCTAssertEqual(element(ID.textBlock(0), in: app).value as? String, "Un café, una libreta y tiempo para crear.")
        XCTAssertEqual(element(ID.pinButton, in: app).value as? String, "Sin fijar")
        XCTAssertFalse(element(ID.headerCategory, in: app).exists)
        XCTAssertEqual(app.alerts.count, 0)
        XCTAssertEqual(app.sheets.count, 0)
        XCTAssertEqual(app.keyboards.count, 0)
        XCTAssertFalse(element(ID.listCounter, in: app).exists)
    }

    // MARK: - Error al guardar

    func testGivenUnavailableStorageWhenWritingAndGoingBackThenShowsErrorAndDiscardDialog() {
        let app = launch(extraArguments: [LaunchArgument.loadFailure])
        XCTAssertTrue(element(ID.listError, in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element(ID.newNoteButton, in: app).isHittable)

        openNewNote(in: app)
        type("Borrador", into: element(ID.titleField, in: app))

        let saveError = element(ID.saveError, in: app)
        XCTAssertTrue(saveError.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(saveError.label, "No se pudieron guardar los cambios. Lo que escribiste sigue aquí.")

        element(ID.backButton, in: app).tap()
        let dialog = app.alerts["No se pudieron guardar los cambios"]
        XCTAssertTrue(dialog.waitForExistence(timeout: timeout), app.debugDescription)
        dialog.buttons["Seguir editando"].tap()

        XCTAssertTrue(waitForNonExistence(of: dialog))
        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "Borrador")
        XCTAssertFalse(element(ID.listError, in: app).exists)

        element(ID.backButton, in: app).tap()
        XCTAssertTrue(dialog.waitForExistence(timeout: timeout), app.debugDescription)
        dialog.buttons["Descartar cambios"].tap()

        XCTAssertTrue(element(ID.listError, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertFalse(element(ID.titleField, in: app).exists)
        XCTAssertEqual(cards(in: app).count, 0)
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

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func cards(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: ID.listCard)
    }

    private func card(titled title: String, in app: XCUIApplication) -> XCUIElement {
        cards(in: app).matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    /// Marco de cada tarjeta de ejemplo, por título.
    private func cardFrames(in app: XCUIApplication) -> [String: CGRect] {
        Dictionary(uniqueKeysWithValues: sampleTitles.map { ($0, card(titled: $0, in: app).frame) })
    }

    private func openNewNote(in app: XCUIApplication) {
        let button = element(ID.newNoteButton, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()
        XCTAssertTrue(element(ID.titleField, in: app).waitForExistence(timeout: timeout), app.debugDescription)
    }

    private func openNote(titled title: String, in app: XCUIApplication) {
        let card = card(titled: title, in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        card.tap()
        XCTAssertTrue(element(ID.titleField, in: app).waitForExistence(timeout: timeout), app.debugDescription)
    }

    private func goBackToList(in app: XCUIApplication) {
        element(ID.backButton, in: app).tap()
        XCTAssertTrue(element(ID.listCounter, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(waitForNonExistence(of: element(ID.titleField, in: app)), app.debugDescription)
    }

    private func type(_ text: String, into field: XCUIElement) {
        field.tap()
        field.typeText(text)
    }

    /// Borra todo el texto: pone el cursor al final (esquina inferior derecha) y borra carácter a carácter.
    private func clear(_ field: XCUIElement) {
        let length = (field.value as? String)?.count ?? 0
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.9)).tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length + 2))
    }

    private func waitForNonExistence(of element: XCUIElement) -> Bool {
        element.waitForNonExistence(timeout: timeout)
    }

    private func assertSampleNotesOnly(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(
            element(ID.listCounter, in: app).label,
            "6 notas · un espacio para tus ideas",
            file: file,
            line: line
        )
        XCTAssertEqual(cards(in: app).count, sampleNoteCount, file: file, line: line)
        for title in sampleTitles {
            XCTAssertTrue(card(titled: title, in: app).exists, title, file: file, line: line)
        }
    }
}
