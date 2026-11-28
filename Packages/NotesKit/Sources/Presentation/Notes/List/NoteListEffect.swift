enum NoteListEffect: Equatable, Sendable {
    /// Abrir otra pantalla; `NoteListRoute` lo entrega a quien gestiona la navegación.
    case open(NotesDestination)
    /// Anunciar a VoiceOver el resultado de la búsqueda tras 1 s sin cambios (spec 004, RF-42, RF-43).
    case announce(NoteListAnnouncement)
}

/// Qué anunciar a VoiceOver al terminar de escribir en el buscador (spec 004).
enum NoteListAnnouncement: Equatable, Sendable {
    /// "3 resultados" (RF-42).
    case results(Int)
    /// "No hay notas que coincidan con «texto»", con el texto sin espacios exteriores (RF-43).
    case noMatches(String)
}
