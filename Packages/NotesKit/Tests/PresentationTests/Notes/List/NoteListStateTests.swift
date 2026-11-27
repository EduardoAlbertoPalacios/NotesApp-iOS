import Domain
import Testing
@testable import Presentation

/// `isEmpty` decide si "Mis notas" muestra el estado vacío (spec 003, RF-24); los derivados de búsqueda,
/// qué muestra la cuadrícula y el buscador (spec 004, RF-4, RF-18, RF-19, RF-32 a RF-36).
struct NoteListStateTests {
    @Test("given still loading without notes when checking isEmpty then is false")
    func loadingIsNotEmpty() {
        let state = NoteListState(isLoading: true, notes: [], loadError: nil)

        #expect(state.isEmpty == false)
    }

    @Test("given load error without notes when checking isEmpty then is false")
    func loadErrorIsNotEmpty() {
        let state = NoteListState(isLoading: false, notes: [], loadError: .loadFailed)

        #expect(state.isEmpty == false)
    }

    @Test("given loaded notes when checking isEmpty then is false")
    func withNotesIsNotEmpty() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], loadError: nil)

        #expect(state.isEmpty == false)
    }

    @Test("given loaded without notes nor error when checking isEmpty then is true")
    func loadedWithoutNotesIsEmpty() {
        let state = NoteListState(isLoading: false, notes: [], loadError: nil)

        #expect(state.isEmpty)
    }

    @Test("given loaded without notes and a deleted banner when checking isEmpty then is still true")
    func emptyWithBannerIsEmpty() {
        let state = NoteListState(isLoading: false, notes: [], loadError: nil, banner: .deleted(.fixture()))

        #expect(state.isEmpty)
    }

    // MARK: - Búsqueda (spec 004)

    @Test("given empty search text when checking isSearching then is false")
    func emptyTextIsNotSearching() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "")

        #expect(state.isSearching == false)
    }

    @Test("given search text with only spaces when checking isSearching then is false")
    func whitespaceTextIsNotSearching() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "   ")

        #expect(state.isSearching == false)
    }

    @Test("given search text with words and outer spaces when checking isSearching then is true")
    func textWithWordsIsSearching() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "  reu ")

        #expect(state.isSearching)
    }

    @Test("given not searching when reading visibleNotes then returns all notes")
    func visibleNotesWithoutSearchAreAllNotes() {
        let notes = [Note.fixture(title: "Una"), Note.fixture(title: "Otra")]
        let state = NoteListState(isLoading: false, notes: notes, searchText: "  ")

        #expect(state.visibleNotes == notes)
    }

    @Test("given searching when reading visibleNotes then returns the results")
    func visibleNotesWhileSearchingAreResults() {
        let match = Note.fixture(title: "Una")
        let state = NoteListState(isLoading: false, notes: [match, .fixture(title: "Otra")], searchText: "una", results: [match])

        #expect(state.visibleNotes == [match])
    }

    @Test("given searching without results when reading visibleNotes then is empty")
    func visibleNotesWithoutResultsIsEmpty() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "xyz", results: [])

        #expect(state.visibleNotes.isEmpty)
    }

    @Test("given still loading even with notes when checking isSearchEnabled then is false")
    func loadingDisablesSearch() {
        let state = NoteListState(isLoading: true, notes: [.fixture()])

        #expect(state.isSearchEnabled == false)
    }

    @Test("given load error when checking isSearchEnabled then is false")
    func loadErrorDisablesSearch() {
        let state = NoteListState(isLoading: false, notes: [], loadError: .loadFailed)

        #expect(state.isSearchEnabled == false)
    }

    @Test("given loaded without notes when checking isSearchEnabled then is false")
    func noNotesDisablesSearch() {
        let state = NoteListState(isLoading: false, notes: [])

        #expect(state.isSearchEnabled == false)
    }

    @Test("given loaded with notes when checking isSearchEnabled then is true")
    func notesEnableSearch() {
        let state = NoteListState(isLoading: false, notes: [.fixture()])

        #expect(state.isSearchEnabled)
    }

    @Test("given searching with notes and no results when checking hasNoResults then is true and isEmpty is false")
    func searchWithoutMatchesHasNoResults() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "xyz", results: [])

        #expect(state.hasNoResults)
        #expect(state.isEmpty == false)
    }

    @Test("given searching with results when checking hasNoResults then is false")
    func searchWithMatchesHasResults() {
        let match = Note.fixture()
        let state = NoteListState(isLoading: false, notes: [match], searchText: "tít", results: [match])

        #expect(state.hasNoResults == false)
    }

    @Test("given not searching when checking hasNoResults then is false")
    func noSearchHasNoNoResultsMessage() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], searchText: "  ", results: [])

        #expect(state.hasNoResults == false)
    }

    @Test("given searching without notes when checking hasNoResults then is false")
    func searchWithoutNotesHasNoNoResultsMessage() {
        let state = NoteListState(isLoading: false, notes: [], searchText: "xyz", results: [])

        #expect(state.hasNoResults == false)
    }

    @Test("given searching while loading when checking hasNoResults then is false")
    func searchWhileLoadingHasNoNoResultsMessage() {
        let state = NoteListState(isLoading: true, notes: [.fixture()], searchText: "xyz", results: [])

        #expect(state.hasNoResults == false)
    }

    @Test("given searching with load error when checking hasNoResults then is false")
    func searchWithLoadErrorHasNoNoResultsMessage() {
        let state = NoteListState(isLoading: false, notes: [.fixture()], loadError: .loadFailed, searchText: "xyz", results: [])

        #expect(state.hasNoResults == false)
    }
}
