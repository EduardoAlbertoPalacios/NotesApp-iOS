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
}
