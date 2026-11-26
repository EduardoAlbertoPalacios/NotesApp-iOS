import XCTest

/// Pruebas de UI de la eliminación de notas (spec 003): menú ⋯ del editor, aviso "Nota eliminada"
/// con "Deshacer" en "Mis notas" y estado vacío. La app se lanza con `-UITesting`: almacén en
/// memoria con las 6 notas de ejemplo; solo "Reunión de equipo" está fijada.
///
/// Menú ⋯: es un `Menu` de SwiftUI. Tras tocar `noteEditor.moreButton`, la opción aparece como un
/// botón con el identificador `noteEditor.menu.delete` en el árbol de la app (no hace falta buscarla
/// en `app.collectionViews` ni por texto); se espera con `waitForExistence` porque el menú se anima.
///
/// Fuera de alcance aquí:
/// - Relanzar la app tras una eliminación definitiva: `-UITesting` usa un almacén en memoria y
///   sin él la app usaría el almacén real del simulador; no hay un modo para relanzar conservando
///   datos (lo mismo que RF-31 de la spec 002 en `NoteEditorUITests`). Lo cubren DataTests.
/// - VoiceOver (RF-13, RF-32) y fallo al deshacer (RF-30, RF-31): pruebas unitarias y demo manual.
/// - iPad: el runtime instalado solo admite el simulador `iPhone Duo`.
@MainActor
final class NoteDeletionUITests: XCTestCase {
    /// Copia de `NoteListAccessibilityID` y `NoteEditorAccessibilityID` (el target de UI no
    /// enlaza `Presentation`).
    private enum ID {
        static let listCounter = "noteList.counter"
        static let listCard = "noteList.card"
        static let listError = "noteList.error"
        static let newNoteButton = "noteList.newNoteButton"
        static let emptyState = "noteList.emptyState"
        static let undoBanner = "noteList.undoBanner"
        static let undoButton = "noteList.undoButton"
        static let backButton = "noteEditor.backButton"
        static let moreButton = "noteEditor.moreButton"
        static let deleteMenuItem = "noteEditor.menu.delete"
        static let titleField = "noteEditor.titleField"

        static func textBlock(_ index: Int) -> String { "noteEditor.textBlock.\(index)" }
    }

    private enum LaunchArgument {
        static let uiTesting = "-UITesting"
        static let loadFailure = "-UITestingLoadFailure"
    }

    private let timeout: TimeInterval = 10
    /// El aviso caduca a los 5 s (RF-12); margen para la animación y la lentitud del simulador.
    private let bannerExpiryTimeout: TimeInterval = 8
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

    // MARK: - Menú ⋯ (RF-1 a RF-3)

    func testGivenEditorWhenOpeningMoreMenuThenShowsDeleteAndClosingItKeepsEditorUnchanged() {
        let app = launch()
        openNote(titled: "Ideas sueltas", in: app)

        element(ID.moreButton, in: app).tap()
        let deleteItem = element(ID.deleteMenuItem, in: app)
        XCTAssertTrue(deleteItem.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(deleteItem.label, "Eliminar nota")
        XCTAssertEqual(element(ID.moreButton, in: app).label, "Más opciones")

        // Toque fuera del menú, en la zona vacía bajo el contenido.
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()

        XCTAssertTrue(deleteItem.waitForNonExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(element(ID.titleField, in: app).exists)
        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "Ideas sueltas")
        XCTAssertEqual(
            element(ID.textBlock(0), in: app).value as? String,
            "Un café, una libreta y tiempo para crear."
        )
        XCTAssertFalse(element(ID.listCounter, in: app).exists)
        XCTAssertEqual(app.alerts.count, 0)
    }

    // MARK: - Eliminar y deshacer (RF-4 a RF-6, RF-10, RF-15 a RF-19)

    func testGivenSampleNoteWhenDeletingThenReturnsToListWithoutCardAndShowsBanner() throws {
        let app = launch()
        openNote(titled: "Ideas sueltas", in: app)

        deleteOpenNote(in: app, expectingBanner: true)

        // Una sola instantánea: el aviso caduca a los 5 s y cada consulta de XCUITest tarda ~1 s.
        let screen = try app.snapshot()
        let banner = try XCTUnwrap(find(ID.undoBanner, in: screen), app.debugDescription)
        XCTAssertTrue(contains(label: "Nota eliminada", in: banner), "Aviso: \(banner.dictionaryRepresentation)")
        XCTAssertEqual(find(ID.undoButton, in: screen)?.label, "Deshacer")
        XCTAssertEqual(find(ID.listCounter, in: screen)?.label, "5 notas · un espacio para tus ideas")
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, sampleNoteCount - 1)
        XCTAssertFalse(findAll(ID.listCard, in: screen).contains { $0.label.hasPrefix("Ideas sueltas") })
        XCTAssertTrue(contains(label: "Mis notas", in: screen))
        XCTAssertFalse(contains(identifier: ID.titleField, in: screen))
    }

    func testGivenDeletedNoteWhenTappingUndoThenCardReturnsInSamePositionAndBannerHides() {
        let app = launch()
        XCTAssertTrue(cards(in: app).firstMatch.waitForExistence(timeout: timeout))
        let title = "Ideas sueltas"
        let before = card(titled: title, in: app)
        let frameBefore = before.frame
        let labelBefore = before.label
        let indexBefore = gridIndex(ofCardTitled: title, in: app)
        XCTAssertNotNil(indexBefore)

        openNote(titled: title, in: app)
        deleteOpenNote(in: app, expectingBanner: true)
        element(ID.undoButton, in: app).tap()

        XCTAssertTrue(waitForNonExistence(of: element(ID.undoBanner, in: app)), app.debugDescription)
        let restored = card(titled: title, in: app)
        XCTAssertTrue(restored.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "6 notas · un espacio para tus ideas")
        XCTAssertEqual(restored.label, labelBefore)
        XCTAssertEqual(gridIndex(ofCardTitled: title, in: app), indexBefore)
        XCTAssertEqual(restored.frame, frameBefore)
    }

    // MARK: - Caducidad y eliminación definitiva (RF-12, RF-14, RF-20, RF-23)

    func testGivenBannerWhenWaitingWithoutTouchingThenBannerHidesAndNoteDoesNotReturn() {
        let app = launch()
        openNote(titled: "Escapada", in: app)
        deleteOpenNote(in: app, expectingBanner: true)
        let banner = element(ID.undoBanner, in: app)

        XCTAssertTrue(banner.waitForNonExistence(timeout: bannerExpiryTimeout), app.debugDescription)

        XCTAssertFalse(card(titled: "Escapada", in: app).exists)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount - 1)
        XCTAssertFalse(element(ID.undoButton, in: app).exists)
    }

    func testGivenBannerWhenOpeningAnotherNoteAndGoingBackThenNoBannerAndDeletedNoteStaysGone() {
        let app = launch()
        openNote(titled: "Escapada", in: app)
        deleteOpenNote(in: app, expectingBanner: true)

        openNote(titled: "Para leer", in: app)
        goBackToList(in: app)

        XCTAssertFalse(element(ID.undoBanner, in: app).exists, app.debugDescription)
        XCTAssertFalse(card(titled: "Escapada", in: app).exists)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount - 1)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "5 notas · un espacio para tus ideas")
    }

    // MARK: - Nota nueva (RF-7 a RF-9, RF-17)

    /// XCUITest no garantiza que el menú se toque antes del guardado automático de 1 s; la prueba
    /// elimina lo antes posible y comprueba lo que la spec exige en ambos casos: aviso, la nota no
    /// queda en la lista y "Deshacer" la recupera con lo escrito.
    func testGivenNewNoteWithTextWhenDeletingRightAwayThenUndoRecoversItsText() throws {
        let app = launch()
        openNewNote(in: app)
        let text = "Llamar al dentista"

        type(text, into: element(ID.textBlock(0), in: app))
        deleteOpenNote(in: app, expectingBanner: true)

        let screen = try app.snapshot()
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, sampleNoteCount)
        XCTAssertFalse(findAll(ID.listCard, in: screen).contains { $0.label.contains(text) })

        element(ID.undoButton, in: app).tap()

        let recovered = card(containing: text, in: app)
        XCTAssertTrue(recovered.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertTrue(recovered.label.hasPrefix("Sin título"), "Etiqueta: \(recovered.label)")
        XCTAssertEqual(cards(in: app).count, sampleNoteCount + 1)
        XCTAssertTrue(waitForNonExistence(of: element(ID.undoBanner, in: app)), app.debugDescription)
    }

    func testGivenEmptyNewNoteWhenDeletingThenReturnsToListWithoutBannerOrNewNote() {
        let app = launch()
        openNewNote(in: app)

        deleteOpenNote(in: app, expectingBanner: false)

        XCTAssertFalse(element(ID.undoBanner, in: app).waitForExistence(timeout: 2), app.debugDescription)
        XCTAssertEqual(cards(in: app).count, sampleNoteCount)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "6 notas · un espacio para tus ideas")
        for title in sampleTitles {
            XCTAssertTrue(card(titled: title, in: app).exists, title)
        }
    }

    // MARK: - Estado vacío (RF-24 a RF-26)

    func testGivenAllNotesDeletedWhenListAppearsThenShowsEmptyStateAndUndoRestoresLastNote() throws {
        let app = launch()
        XCTAssertTrue(cards(in: app).firstMatch.waitForExistence(timeout: timeout))

        for remaining in stride(from: sampleNoteCount, to: 0, by: -1) {
            XCTAssertEqual(cards(in: app).count, remaining)
            let first = cards(in: app).firstMatch
            first.tap()
            XCTAssertTrue(element(ID.titleField, in: app).waitForExistence(timeout: timeout), app.debugDescription)
            deleteOpenNote(in: app, expectingBanner: true)
        }

        // Una sola instantánea antes de "Deshacer": el aviso caduca a los 5 s.
        let screen = try app.snapshot()
        let empty = try XCTUnwrap(find(ID.emptyState, in: screen), app.debugDescription)
        XCTAssertTrue(empty.label.contains("Aún no tienes notas."), "Etiqueta: \(empty.label)")
        XCTAssertTrue(empty.label.contains("Crea la primera."), "Etiqueta: \(empty.label)")
        XCTAssertEqual(findAll(ID.listCard, in: screen).count, 0)
        XCTAssertEqual(find(ID.listCounter, in: screen)?.label, "0 notas · un espacio para tus ideas")
        let newNote = try XCTUnwrap(find(ID.newNoteButton, in: screen))
        XCTAssertTrue(screen.frame.contains(newNote.frame), "Marco: \(newNote.frame)")
        XCTAssertNotNil(find(ID.undoButton, in: screen))

        element(ID.undoButton, in: app).tap()
        let emptyState = element(ID.emptyState, in: app)

        XCTAssertTrue(waitForNonExistence(of: emptyState), app.debugDescription)
        XCTAssertTrue(cards(in: app).firstMatch.waitForExistence(timeout: timeout), app.debugDescription)
        XCTAssertEqual(cards(in: app).count, 1)
        XCTAssertEqual(element(ID.listCounter, in: app).label, "1 nota · un espacio para tus ideas")
    }

    // MARK: - Error al eliminar (RF-27 a RF-29)

    func testGivenUnavailableStorageWhenDeletingNewNoteThenShowsAlertAndKeepsEditorText() {
        let app = launch(extraArguments: [LaunchArgument.loadFailure])
        XCTAssertTrue(element(ID.listError, in: app).waitForExistence(timeout: timeout))
        openNewNote(in: app)
        type("Borrador", into: element(ID.titleField, in: app))

        tapDeleteInMoreMenu(in: app)

        let alert = app.alerts["No se pudo eliminar la nota"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout), app.debugDescription)
        alert.buttons["Aceptar"].tap()

        XCTAssertTrue(waitForNonExistence(of: alert), app.debugDescription)
        XCTAssertTrue(element(ID.titleField, in: app).exists)
        XCTAssertEqual(element(ID.titleField, in: app).value as? String, "Borrador")
        XCTAssertFalse(element(ID.listError, in: app).exists)
        XCTAssertFalse(element(ID.undoBanner, in: app).exists)
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

    private func card(containing text: String, in app: XCUIApplication) -> XCUIElement {
        cards(in: app).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Índice de la tarjeta en el orden de lectura de la cuadrícula (fila a fila, de izquierda a
    /// derecha). El orden del árbol de accesibilidad no sirve: XCUITest lo ordena por coordenada Y.
    private func gridIndex(ofCardTitled title: String, in app: XCUIApplication) -> Int? {
        let elements: [XCUIElement] = cards(in: app).allElementsBoundByIndex
        let entries: [(label: String, frame: CGRect)] = elements.map { ($0.label, $0.frame) }
        let sorted = entries.sorted { (lhs: (label: String, frame: CGRect), rhs: (label: String, frame: CGRect)) -> Bool in
            let dy: CGFloat = lhs.frame.minY - rhs.frame.minY
            if abs(dy) > 1 { return dy < 0 }
            return lhs.frame.minX < rhs.frame.minX
        }
        return sorted.firstIndex { $0.label.hasPrefix(title) }
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

    /// Abre el menú ⋯ y elige "Eliminar nota".
    private func tapDeleteInMoreMenu(in app: XCUIApplication) {
        element(ID.moreButton, in: app).tap()
        let deleteItem = element(ID.deleteMenuItem, in: app)
        XCTAssertTrue(deleteItem.waitForExistence(timeout: timeout), app.debugDescription)
        deleteItem.tap()
    }

    /// Elimina la nota abierta y espera a volver a "Mis notas". Si se espera el aviso, lo busca
    /// antes que nada: caduca a los 5 s y cada consulta de XCUITest tarda alrededor de 1 s.
    private func deleteOpenNote(in app: XCUIApplication, expectingBanner: Bool) {
        tapDeleteInMoreMenu(in: app)
        if expectingBanner {
            XCTAssertTrue(element(ID.undoBanner, in: app).waitForExistence(timeout: timeout), app.debugDescription)
        } else {
            XCTAssertTrue(element(ID.listCounter, in: app).waitForExistence(timeout: timeout), app.debugDescription)
            XCTAssertTrue(waitForNonExistence(of: element(ID.titleField, in: app)), app.debugDescription)
        }
    }

    // MARK: - Instantáneas (una sola consulta a la app)

    private func findAll(_ identifier: String, in snapshot: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        let own: [any XCUIElementSnapshot] = snapshot.identifier == identifier ? [snapshot] : []
        return own + snapshot.children.flatMap { findAll(identifier, in: $0) }
    }

    private func find(_ identifier: String, in snapshot: any XCUIElementSnapshot) -> (any XCUIElementSnapshot)? {
        findAll(identifier, in: snapshot).first
    }

    private func contains(identifier: String, in snapshot: any XCUIElementSnapshot) -> Bool {
        find(identifier, in: snapshot) != nil
    }

    private func contains(label: String, in snapshot: any XCUIElementSnapshot) -> Bool {
        snapshot.label == label || snapshot.children.contains { contains(label: label, in: $0) }
    }

    private func type(_ text: String, into field: XCUIElement) {
        field.tap()
        field.typeText(text)
    }

    private func waitForNonExistence(of element: XCUIElement) -> Bool {
        element.waitForNonExistence(timeout: timeout)
    }
}
