import Domain

struct NoteListState: Equatable, Sendable {
    var isLoading = true
    var notes: [Note] = []
    var loadError: NoteListError?
    /// Aviso inferior tras eliminar una nota (spec 003, RF-10 y RF-30).
    var banner: NoteListBanner?

    /// Sin notas que mostrar: estado vacío (spec 003, RF-24).
    var isEmpty: Bool { !isLoading && loadError == nil && notes.isEmpty }
}

enum NoteListError: Equatable, Sendable {
    case loadFailed
}

enum NoteListBanner: Equatable, Sendable {
    /// "Nota eliminada" con "Deshacer"; contiene la copia para recuperarla.
    case deleted(Note)
    /// "No se pudo recuperar la nota".
    case restoreFailed
}
