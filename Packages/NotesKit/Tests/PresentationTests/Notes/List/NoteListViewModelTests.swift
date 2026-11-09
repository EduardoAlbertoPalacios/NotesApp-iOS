import Common
import Domain
import Testing
@testable import Presentation

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NoteListViewModelTests {
    private func makeViewModel(
        repository: FakeNoteRepository = FakeNoteRepository(finishesStreams: true),
        settings: FakeSettingsRepository = FakeSettingsRepository()
    ) -> NoteListViewModel {
        NoteListViewModel(
            observeNotes: ObserveNotesUseCase(repository: repository),
            seedSampleNotes: SeedSampleNotesUseCase(
                notes: repository,
                settings: settings,
                dateProvider: FixedDateProvider()
            )
        )
    }

    private let sampleTitlesInOrder = [
        "Reunión de equipo", "La compra", "Ideas sueltas", "Escapada", "Para leer", "Una buena idea",
    ]

    @Test("given new view model when created then state is loading without notes or error")
    func initialState() {
        let viewModel = makeViewModel()

        #expect(viewModel.state == NoteListState(isLoading: true, notes: [], loadError: nil))
        #expect(viewModel.reloadToken == 0)
    }

    @Test("given first launch when starting then seeds the six sample notes in order and stops loading")
    func startSeedsSampleNotes() async {
        let settings = FakeSettingsRepository()
        let viewModel = makeViewModel(settings: settings)

        await viewModel.start()

        #expect(viewModel.state.notes.map(\.title) == sampleTitlesInOrder)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.loadError == nil)
        #expect(settings.hasSeededSampleNotes)
    }

    @Test("given sample notes already seeded when starting then shows stored notes without seeding again")
    func startDoesNotSeedTwice() async {
        let stored = Note.fixture(title: "Mía")
        let repository = FakeNoteRepository(notes: [stored], finishesStreams: true)
        let viewModel = makeViewModel(repository: repository, settings: FakeSettingsRepository(hasSeededSampleNotes: true))

        await viewModel.start()

        #expect(viewModel.state.notes == [stored])
        #expect(viewModel.state.isLoading == false)
    }

    @Test("given seeding fails when starting then shows load error and stops loading")
    func seedFailureShowsError() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)

        await viewModel.start()

        #expect(viewModel.state.loadError == .loadFailed)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.notes.isEmpty)
    }

    @Test("given stream emits failure when starting then shows load error")
    func streamFailureShowsError() async {
        let repository = FakeNoteRepository(readFailure: .corruptedData, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository, settings: FakeSettingsRepository(hasSeededSampleNotes: true))

        await viewModel.start()

        #expect(viewModel.state.loadError == .loadFailed)
        #expect(viewModel.state.isLoading == false)
    }

    @Test("given stream emits failure then success when starting then error is cleared and notes shown")
    func streamSuccessAfterFailureClearsError() async {
        let note = Note.fixture()
        let repository = FakeNoteRepository(
            scriptedReads: [.failure(.storageUnavailable), .success([note])],
            finishesStreams: true
        )
        let viewModel = makeViewModel(repository: repository, settings: FakeSettingsRepository(hasSeededSampleNotes: true))

        await viewModel.start()

        #expect(viewModel.state.loadError == nil)
        #expect(viewModel.state.notes == [note])
        #expect(viewModel.state.isLoading == false)
    }

    @Test("given retry tapped when intent sent then reload token increments and state is unchanged")
    func retryIncrementsReloadToken() {
        let viewModel = makeViewModel()
        let stateBefore = viewModel.state

        viewModel.send(.retryTapped)
        viewModel.send(.retryTapped)

        #expect(viewModel.reloadToken == 2)
        #expect(viewModel.state == stateBefore)
    }

    @Test("given previous load failed when starting again after fix then loads notes and clears error")
    func startAfterErrorLoadsSuccessfully() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        await viewModel.start()
        repository.failSaves(with: nil)

        viewModel.send(.retryTapped)
        await viewModel.start()

        #expect(viewModel.state.loadError == nil)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.notes.map(\.title) == sampleTitlesInOrder)
    }

    @Test("given task cancelled when seeding fails then load error is not set")
    func cancelledSeedFailureIsSilent() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)

        let task = Task { await viewModel.start() }
        task.cancel()
        await task.value

        #expect(viewModel.state.loadError == nil)
    }

    @Test("given task cancelled when stream emits failure then load error is not set")
    func cancelledStreamFailureIsSilent() async {
        let repository = FakeNoteRepository(readFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository, settings: FakeSettingsRepository(hasSeededSampleNotes: true))

        let task = Task { await viewModel.start() }
        task.cancel()
        await task.value

        #expect(viewModel.state.loadError == nil)
    }
}
