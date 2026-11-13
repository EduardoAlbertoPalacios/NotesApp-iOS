import Domain

struct NoteListState: Equatable, Sendable {
    var isLoading = true
    var notes: [Note] = []
    var loadError: NoteListError?
}

enum NoteListError: Equatable, Sendable {
    case loadFailed
}
