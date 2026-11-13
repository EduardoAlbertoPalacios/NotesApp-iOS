enum NoteListEffect: Equatable, Sendable {
    /// Abrir otra pantalla; `NoteListRoute` lo entrega a quien gestiona la navegación.
    case open(NotesDestination)
}
