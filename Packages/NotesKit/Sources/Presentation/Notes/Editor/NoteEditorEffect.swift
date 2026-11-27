import Domain

enum NoteEditorEffect: Equatable, Sendable {
    /// Volver a "Mis notas".
    case close
    /// Volver a "Mis notas" tras eliminar la nota; lleva la copia para "Deshacer" (spec 003, RF-5, RF-10).
    case deleted(Note)
}
