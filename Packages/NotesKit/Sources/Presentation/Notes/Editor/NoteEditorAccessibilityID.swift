import Domain

/// Identificadores para las pruebas de UI del editor.
enum NoteEditorAccessibilityID {
    static let screen = "noteEditor.screen"
    static let backButton = "noteEditor.backButton"
    static let pinButton = "noteEditor.pinButton"
    static let shareButton = "noteEditor.shareButton"
    static let moreButton = "noteEditor.moreButton"
    static let headerCategory = "noteEditor.header.category"
    static let headerDate = "noteEditor.header.date"
    static let titleField = "noteEditor.titleField"
    static let saveStatus = "noteEditor.saveStatus"
    static let saveError = "noteEditor.saveError"
    static let formatButton = "noteEditor.toolbar.format"
    static let checklistButton = "noteEditor.toolbar.checklist"
    static let imageButton = "noteEditor.toolbar.image"
    static let undoButton = "noteEditor.toolbar.undo"
    static let colorButton = "noteEditor.toolbar.color"

    /// `noteEditor.category.work` / `noteEditor.category.personal`.
    static func category(_ category: NoteCategory) -> String { "noteEditor.category.\(category.rawValue)" }

    /// Campo del bloque de texto `index`. En una nota nueva, el contenido es el bloque 0.
    static func textBlock(_ index: Int) -> String { "noteEditor.textBlock.\(index)" }

    /// Fila de la tarea del bloque `index`.
    static func task(_ index: Int) -> String { "noteEditor.task.\(index)" }
}
