import Domain

struct NoteListState: Equatable, Sendable {
    var isLoading = true
    /// Todas las notas, ordenadas; con búsqueda, la cuadrícula muestra `results` (spec 004).
    var notes: [Note] = []
    var loadError: NoteListError?
    /// Aviso inferior tras eliminar una nota (spec 003, RF-10 y RF-30).
    var banner: NoteListBanner?
    /// Texto del buscador, tal como lo escribió el usuario (spec 004).
    var searchText = ""
    /// Notas que coinciden con `searchText`, en el orden de `notes` (spec 004, RF-1, RF-14).
    var results: [Note] = []

    /// Sin notas que mostrar: estado vacío (spec 003, RF-24).
    var isEmpty: Bool { !isLoading && loadError == nil && notes.isEmpty }

    /// Hay palabras que buscar: vacío o solo espacios no cuenta como búsqueda (spec 004, RF-4).
    var isSearching: Bool { !NoteSearch.words(in: searchText).isEmpty }

    /// Lo que muestra la cuadrícula.
    var visibleNotes: [Note] { isSearching ? results : notes }

    /// El buscador solo se usa con las notas cargadas, sin error y con al menos una (RF-32, RF-35, RF-36).
    var isSearchEnabled: Bool { !isLoading && loadError == nil && !notes.isEmpty }

    /// Se busca, hay notas y ninguna coincide: mensaje de sin resultados (RF-18, RF-19).
    var hasNoResults: Bool { isSearching && !isLoading && loadError == nil && !notes.isEmpty && results.isEmpty }
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
