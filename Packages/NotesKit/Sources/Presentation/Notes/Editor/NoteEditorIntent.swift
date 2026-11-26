import Domain

enum NoteEditorIntent: Equatable, Sendable {
    case titleChanged(String)
    /// Cambio en el bloque de texto `index` de `NoteEditorState.blocks`.
    case textBlockChanged(index: Int, text: String)
    case categoryTapped(NoteCategory)
    case pinTapped
    case backTapped
    case discardConfirmed
    case keepEditingTapped
    /// Opción "Eliminar nota" del menú ⋯ (spec 003, RF-4).
    case deleteTapped
    /// Cierre de la alerta de error al eliminar (spec 003, RF-28).
    case deleteErrorDismissed
}
