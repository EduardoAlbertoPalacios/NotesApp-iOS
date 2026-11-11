import Domain

enum NoteListIntent: Equatable, Sendable {
    case retryTapped
    /// Botón "Nueva nota" (spec 002, RF-1).
    case newNoteTapped
    /// Tarjeta de una nota (spec 002, RF-4).
    case noteTapped(Note)
}
