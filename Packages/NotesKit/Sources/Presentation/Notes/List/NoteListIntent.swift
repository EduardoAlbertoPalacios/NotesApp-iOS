import Domain

enum NoteListIntent: Equatable, Sendable {
    case retryTapped
    /// Botón "Nueva nota" (spec 002, RF-1).
    case newNoteTapped
    /// Tarjeta de una nota (spec 002, RF-4).
    case noteTapped(Note)
    /// Se eliminó una nota en el editor (spec 003, RF-10).
    case noteDeleted(NoteDeletion)
    /// Botón "Deshacer" del aviso (spec 003, RF-15, RF-16).
    case undoTapped
    /// VoiceOver se activó o desactivó; con VoiceOver el aviso no caduca (spec 003, RF-12, RF-13).
    case voiceOverChanged(Bool)
    /// La app pasó a segundo plano (spec 003, RF-22).
    case movedToBackground
}
