import Domain
import Testing
@testable import Presentation

/// `isEmpty` decide si "Mis notas" muestra el estado vacío (spec 003, RF-24).
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
}
