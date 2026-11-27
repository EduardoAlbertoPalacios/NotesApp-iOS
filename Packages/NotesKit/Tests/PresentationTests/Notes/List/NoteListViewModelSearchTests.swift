import Common
import Domain
import Foundation
import Testing
@testable import Presentation

/// Búsqueda en "Mis notas" y su anuncio a VoiceOver (spec 004, RF-1 a RF-4, RF-15 a RF-22, RF-25 a RF-29,
/// RF-32 a RF-38 y RF-42 a RF-44).
/// Para comprobar que no hay anuncio se envía "Nueva nota": si su efecto es el siguiente, no había nada antes.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NoteListViewModelSearchTests {
    private let clock = ManualClock()

    private let meeting = Note.fixture(title: "Reunión de equipo", blocks: [.text("Revisar objetivos")], sequence: 0)
    private let shopping = Note.fixture(title: "La compra", blocks: [.text("Leche y pan")], sequence: 1)
    private let ideas = Note.fixture(title: "Ideas sueltas", blocks: [.text("Una app de recetas")], sequence: 2)

    private var allNotes: [Note] { [meeting, shopping, ideas] }

    private func makeViewModel(
        repository: FakeNoteRepository,
        settings: FakeSettingsRepository = FakeSettingsRepository(hasSeededSampleNotes: true)
    ) -> NoteListViewModel {
        NoteListViewModel(
            observeNotes: ObserveNotesUseCase(repository: repository),
            seedSampleNotes: SeedSampleNotesUseCase(
                notes: repository,
                settings: settings,
                dateProvider: FixedDateProvider()
            ),
            restoreNote: RestoreNoteUseCase(repository: repository),
            clock: clock
        )
    }

    /// View model con `notes` ya cargadas y un stream que termina.
    private func makeLoadedViewModel(notes: [Note]? = nil) async -> NoteListViewModel {
        let viewModel = makeViewModel(repository: FakeNoteRepository(notes: notes ?? allNotes, finishesStreams: true))
        await viewModel.start()
        return viewModel
    }

    /// Arranca la observación con un stream que sigue abierto; hay que cancelar la tarea al terminar.
    private func startObserving(_ viewModel: NoteListViewModel) async -> Task<Void, Never> {
        let observation = Task { await viewModel.start() }
        await waitUntil { !viewModel.state.isLoading }
        return observation
    }

    private func stop(_ observation: Task<Void, Never>) async {
        observation.cancel()
        await observation.value
    }

    /// Espera a que la espera del anuncio (u otras) esté dormida en el reloj antes de avanzarlo.
    private func waitForSleepers(_ count: Int = 1) async {
        await waitUntil { clock.sleeperCount == count }
    }

    // MARK: - Filtrar (RF-1, RF-3, RF-4)

    @Test("given loaded notes when typing more characters then results narrow to the matching notes in order")
    func typingNarrowsResults() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.send(.searchTextChanged("r"))
        #expect(viewModel.state.results == [meeting, shopping, ideas])

        viewModel.send(.searchTextChanged("re"))
        #expect(viewModel.state.results == [meeting, ideas])

        viewModel.send(.searchTextChanged("reu"))
        #expect(viewModel.state.results == [meeting])
        #expect(viewModel.state.visibleNotes == [meeting])
        #expect(viewModel.state.searchText == "reu")
    }

    @Test("given a search with one result when deleting characters then results widen again")
    func deletingCharactersWidensResults() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.send(.searchTextChanged("reu"))

        viewModel.send(.searchTextChanged("re"))
        #expect(viewModel.state.results == [meeting, ideas])

        viewModel.send(.searchTextChanged("r"))
        #expect(viewModel.state.results == [meeting, shopping, ideas])
        #expect(viewModel.state.searchText == "r")
    }

    @Test("given loaded notes when search text is only spaces then is not searching and all notes are visible")
    func whitespaceOnlyShowsAllNotes() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.send(.searchTextChanged("   "))

        #expect(viewModel.state.searchText == "   ")
        #expect(viewModel.state.isSearching == false)
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.visibleNotes == allNotes)
    }

    @Test("given an active search when clear search tapped then text is empty and all notes are visible")
    func clearSearchShowsAllNotes() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.send(.searchTextChanged("reu"))

        viewModel.send(.clearSearchTapped)

        #expect(viewModel.state.searchText == "")
        #expect(viewModel.state.isSearching == false)
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.visibleNotes == allNotes)
    }

    // MARK: - Recalcular con las notas nuevas del stream (RF-26 a RF-29)

    @Test("given an active search when a matching note is edited so it no longer matches then it leaves the results")
    func editedNoteStopsMatching() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("reu"))
        var edited = meeting
        edited.title = "Retro"
        edited.blocks = [.text("Qué salió bien")]

        try await repository.save([edited])
        await waitUntil { viewModel.state.notes.contains(edited) }

        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.searchText == "reu")
        await stop(observation)
    }

    @Test("given an active search when a new matching note arrives then it joins the results")
    func newMatchingNoteJoinsResults() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("reu"))
        let newNote = Note.fixture(title: "Reunión con clientes", blocks: [], sequence: 3)

        try await repository.save([newNote])
        await waitUntil { viewModel.state.notes.count == 4 }

        #expect(viewModel.state.results == [meeting, newNote])
        await stop(observation)
    }

    @Test("given an active search when a new non matching note arrives then results are unchanged")
    func newNonMatchingNoteStaysOut() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("reu"))
        let newNote = Note.fixture(title: "Viaje", blocks: [.text("Billetes")], sequence: 3)

        try await repository.save([newNote])
        await waitUntil { viewModel.state.notes.count == 4 }

        #expect(viewModel.state.results == [meeting])
        await stop(observation)
    }

    @Test("given an active search when a matching note is deleted then it leaves the results and text is kept")
    func deletedNoteLeavesResults() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("re"))

        try await repository.delete(id: meeting.id)
        await waitUntil { viewModel.state.notes.count == 2 }

        #expect(viewModel.state.results == [ideas])
        #expect(viewModel.state.searchText == "re")
        await stop(observation)
    }

    @Test("given an active search and a deleted matching note when undo tapped then the note returns to the results")
    func undoRestoresMatchingNoteIntoResults() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("reu"))
        try await repository.delete(id: meeting.id)
        await waitUntil { viewModel.state.notes.count == 2 }
        viewModel.send(.noteDeleted(NoteDeletion(note: meeting)))

        viewModel.send(.undoTapped)
        await waitUntil { viewModel.state.notes.count == 3 }

        #expect(viewModel.state.results == [meeting])
        #expect(viewModel.state.searchText == "reu")
        await stop(observation)
    }

    @Test("given an active search and a deleted non matching note when undo tapped then results are unchanged")
    func undoRestoresNonMatchingNoteOutsideResults() async throws {
        let repository = FakeNoteRepository(notes: allNotes)
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        viewModel.send(.searchTextChanged("reu"))
        try await repository.delete(id: shopping.id)
        await waitUntil { viewModel.state.notes.count == 2 }
        viewModel.send(.noteDeleted(NoteDeletion(note: shopping)))

        viewModel.send(.undoTapped)
        await waitUntil { viewModel.state.notes.count == 3 }

        #expect(viewModel.state.results == [meeting])
        await stop(observation)
    }

    // MARK: - Conservar el texto al navegar (RF-25)

    @Test("given an active search when a note is tapped then opens it and keeps the search")
    func noteTappedKeepsSearch() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))

        viewModel.send(.noteTapped(meeting))

        #expect(await effects.next() == .open(.note(meeting)))
        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results == [meeting])
    }

    @Test("given an active search when new note tapped then opens the editor and keeps the search")
    func newNoteTappedKeepsSearch() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))

        viewModel.send(.newNoteTapped)

        #expect(await effects.next() == .open(.newNote))
        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results == [meeting])
    }

    // MARK: - Sin notas, cargando o con error (RF-32 a RF-38)

    @Test("given an active search when the stream emits an empty list then the search is cleared and nothing is announced")
    func emptyListClearsSearch() async throws {
        let repository = FakeNoteRepository(notes: [meeting])
        let viewModel = makeViewModel(repository: repository)
        let observation = await startObserving(viewModel)
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers()

        try await repository.delete(id: meeting.id)
        await waitUntil { viewModel.state.notes.isEmpty }

        #expect(viewModel.state.searchText == "")
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.isSearchEnabled == false)
        await waitForSleepers(0)
        clock.advance(by: NoteListViewModel.announcementDelay)
        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))
        await stop(observation)
    }

    @Test("given notes still loading when search text arrives then it is kept and applied once notes load")
    func searchWhileLoadingIsAppliedOnLoad() async {
        let viewModel = makeViewModel(repository: FakeNoteRepository(notes: allNotes, finishesStreams: true))

        viewModel.send(.searchTextChanged("reu"))

        #expect(viewModel.state.isLoading)
        #expect(viewModel.state.isSearchEnabled == false)
        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results.isEmpty)

        await viewModel.start()

        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results == [meeting])
        #expect(viewModel.state.visibleNotes == [meeting])
    }

    @Test("given seeding still in progress when search text arrives then it is applied to the seeded notes")
    func searchDuringSeedingIsAppliedOnLoad() async {
        let repository = FakeNoteRepository()
        repository.holdSaves()
        let viewModel = makeViewModel(repository: repository, settings: FakeSettingsRepository())
        let observation = Task { await viewModel.start() }
        await waitUntil { repository.heldSaveCount == 1 }

        viewModel.send(.searchTextChanged("reunion"))
        #expect(viewModel.state.isLoading)
        #expect(viewModel.state.searchText == "reunion")

        repository.releaseSaves()
        await waitUntil { !viewModel.state.isLoading }

        #expect(viewModel.state.results.map(\.title) == ["Reunión de equipo"])
        await stop(observation)
    }

    @Test("given load failed when search text arrives then it is kept and applied after a successful retry")
    func searchWithLoadErrorIsAppliedAfterRetry() async {
        let repository = FakeNoteRepository(notes: allNotes, readFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.start()

        viewModel.send(.searchTextChanged("reu"))

        #expect(viewModel.state.loadError == .loadFailed)
        #expect(viewModel.state.isSearchEnabled == false)
        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results.isEmpty)

        repository.failReads(with: nil)
        viewModel.send(.retryTapped)
        await viewModel.start()

        #expect(viewModel.state.loadError == nil)
        #expect(viewModel.state.searchText == "reu")
        #expect(viewModel.state.results == [meeting])
    }

    // MARK: - Anuncio a VoiceOver (RF-42 a RF-44)

    @Test("given a search with results when 999 ms pass then nothing is announced and at 1 s announces the count")
    func announcesResultsExactlyAfterOneSecond() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("re"))
        await waitForSleepers()

        clock.advance(by: .milliseconds(999))
        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))

        clock.advance(by: .milliseconds(1))

        #expect(await effects.next() == .announce(.results(2)))
    }

    @Test("given text changing again before 1 s when the first wait would end then only the last text is announced 1 s after it")
    func consecutiveChangesRestartTheWait() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("r"))
        await waitForSleepers()
        clock.advance(by: .milliseconds(600))

        viewModel.send(.searchTextChanged("re"))
        await waitForSleepers()
        clock.advance(by: .milliseconds(600))
        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))

        clock.advance(by: .milliseconds(400))

        #expect(await effects.next() == .announce(.results(2)))
    }

    @Test("given a search without matches when 1 s passes then announces no matches with the trimmed text")
    func announcesNoMatchesWithTrimmedText() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("  xyz  "))
        await waitForSleepers()

        clock.advance(by: NoteListViewModel.announcementDelay)

        #expect(viewModel.state.hasNoResults)
        #expect(await effects.next() == .announce(.noMatches("xyz")))
    }

    @Test("given search text with only spaces when 1 s passes then nothing is announced")
    func whitespaceOnlyIsNotAnnounced() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.searchTextChanged("   "))
        await yieldMany()

        #expect(clock.sleeperCount == 0)
        clock.advance(by: NoteListViewModel.announcementDelay)
        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))
    }

    @Test("given a pending announcement when text is emptied then nothing is announced")
    func emptiedTextIsNotAnnounced() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers()

        viewModel.send(.searchTextChanged(""))
        await waitForSleepers(0)
        clock.advance(by: NoteListViewModel.announcementDelay)

        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))
    }

    @Test("given a pending announcement when clear search tapped then nothing is announced")
    func clearedSearchIsNotAnnounced() async {
        let viewModel = await makeLoadedViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers()

        viewModel.send(.clearSearchTapped)
        await waitForSleepers(0)
        clock.advance(by: NoteListViewModel.announcementDelay)

        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))
    }

    @Test("given notes still loading when search text waits 1 s then nothing is announced")
    func searchWhileLoadingIsNotAnnounced() async {
        let viewModel = makeViewModel(repository: FakeNoteRepository(notes: allNotes, finishesStreams: true))
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers()

        clock.advance(by: NoteListViewModel.announcementDelay)
        await waitForSleepers(0)

        await yieldMany()
        viewModel.send(.newNoteTapped)
        #expect(await effects.next() == .open(.newNote))
    }

    // MARK: - Convivencia con el aviso "Deshacer" (spec 003)

    @Test("given the deleted banner visible when typing in the search then the banner stays visible")
    func typingKeepsDeletedBanner() async {
        let viewModel = await makeLoadedViewModel()
        let deleted = Note.fixture(title: "Escapada", sequence: 9)
        viewModel.send(.noteDeleted(NoteDeletion(note: deleted)))
        await waitForSleepers()

        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers(2)
        clock.advance(by: NoteListViewModel.announcementDelay)
        await waitForSleepers()

        #expect(viewModel.state.banner == .deleted(deleted))
        #expect(viewModel.state.results == [meeting])
    }

    // MARK: - Re-suscripción a efectos

    @Test("given first effects subscription cancelled when subscribing again then new stream receives the announcement")
    func announcementSurvivesResubscription() async {
        let viewModel = await makeLoadedViewModel()
        let firstStream = viewModel.effects()
        let firstConsumer = Task {
            var effects = firstStream.makeAsyncIterator()
            return await effects.next()
        }
        firstConsumer.cancel()
        #expect(await firstConsumer.value == nil)
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.searchTextChanged("reu"))
        await waitForSleepers()
        clock.advance(by: NoteListViewModel.announcementDelay)

        #expect(await effects.next() == .announce(.results(1)))
    }
}
