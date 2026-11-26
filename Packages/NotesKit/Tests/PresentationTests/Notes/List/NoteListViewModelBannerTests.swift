import Common
import Domain
import Foundation
import Testing
@testable import Presentation

/// Aviso "Nota eliminada" + "Deshacer" y estado vacío de "Mis notas" (spec 003, RF-10 a RF-26, RF-30, RF-31).
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NoteListViewModelBannerTests {
    private let clock = ManualClock()

    private func makeViewModel(
        repository: FakeNoteRepository = FakeNoteRepository(finishesStreams: true),
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

    /// Espera a que la caducidad del aviso esté dormida en el reloj antes de avanzarlo.
    private func waitForBannerTimeout() async {
        await waitUntil { clock.sleeperCount == 1 }
    }

    // MARK: - Aparición y caducidad (RF-10, RF-12, RF-14)

    @Test("given note deleted when intent sent then shows deleted banner with that note")
    func noteDeletedShowsBanner() {
        let note = Note.fixture(title: "La compra")
        let viewModel = makeViewModel()

        viewModel.send(.noteDeleted(NoteDeletion(note: note)))

        #expect(viewModel.state.banner == .deleted(note))
    }

    @Test("given deleted banner visible when 4.9 seconds pass then it stays and at 5 seconds it hides")
    func bannerHidesExactlyAfterFiveSeconds() async {
        let note = Note.fixture()
        let viewModel = makeViewModel()
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))
        await waitForBannerTimeout()

        clock.advance(by: .milliseconds(4_900))
        await yieldMany()

        #expect(viewModel.state.banner == .deleted(note))

        clock.advance(by: .milliseconds(100))
        await waitUntil { viewModel.state.banner == nil }

        #expect(viewModel.state.banner == nil)
    }

    @Test("given deleted banner expired when undo tapped then nothing is restored")
    func undoAfterExpiryDoesNothing() async {
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        await waitForBannerTimeout()
        clock.advance(by: NoteListViewModel.bannerDuration)
        await waitUntil { viewModel.state.banner == nil }

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 0)
        #expect(viewModel.state.banner == nil)
    }

    @Test("given deleted banner visible when another deletion arrives then the 5 second wait restarts")
    func secondDeletionRestartsTimeout() async {
        let first = Note.fixture(title: "Primera")
        let second = Note.fixture(title: "Segunda")
        let viewModel = makeViewModel()
        viewModel.send(.noteDeleted(NoteDeletion(note: first)))
        await waitForBannerTimeout()
        clock.advance(by: .seconds(3))

        viewModel.send(.noteDeleted(NoteDeletion(note: second)))
        await waitForBannerTimeout()
        clock.advance(by: .milliseconds(4_900))
        await yieldMany()

        #expect(viewModel.state.banner == .deleted(second))

        clock.advance(by: .milliseconds(100))
        await waitUntil { viewModel.state.banner == nil }

        #expect(viewModel.state.banner == nil)
    }

    // MARK: - Deshacer (RF-15 a RF-19, RF-30, RF-31)

    @Test("given deleted banner visible when undo tapped then saves the exact copy and hides the banner")
    func undoRestoresExactCopyAndHides() async {
        let note = Note.fixture(
            title: "Escapada",
            blocks: [.text("Sin guardar")],
            color: .pink,
            category: .personal,
            isPinned: true,
            sequence: 7
        )
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))
        await waitForBannerTimeout()

        viewModel.send(.undoTapped)

        #expect(viewModel.state.banner == nil)
        await waitUntil { repository.saveCallCount == 1 }
        #expect(repository.operations == [.save([note.id])])
        #expect(repository.notes == [note])
        #expect(clock.sleeperCount == 0)
    }

    @Test("given no banner when undo tapped then nothing is restored")
    func undoWithoutBannerDoesNothing() async {
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 0)
        #expect(viewModel.state.banner == nil)
    }

    @Test("given restore fails when undo tapped then shows restore failed banner that also hides after 5 seconds")
    func restoreFailureShowsBannerThatExpires() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        await waitForBannerTimeout()

        viewModel.send(.undoTapped)
        await waitUntil { viewModel.state.banner == .restoreFailed }
        await waitForBannerTimeout()
        clock.advance(by: .milliseconds(4_900))
        await yieldMany()

        #expect(viewModel.state.banner == .restoreFailed)

        clock.advance(by: .milliseconds(100))
        await waitUntil { viewModel.state.banner == nil }

        #expect(viewModel.state.banner == nil)
    }

    @Test("given restore failed banner when undo tapped again then does not retry the restore")
    func restoreFailureIsDefinitive() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable, finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        viewModel.send(.undoTapped)
        await waitUntil { viewModel.state.banner == .restoreFailed }

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 1)
        #expect(viewModel.state.banner == .restoreFailed)
    }

    // MARK: - VoiceOver (RF-12, RF-13)

    @Test("given VoiceOver on when banner shown then it never expires and after turning VoiceOver off it hides 5 seconds later")
    func voiceOverOnBeforeBannerKeepsItUntilTurnedOff() async {
        let note = Note.fixture()
        let viewModel = makeViewModel()
        viewModel.send(.voiceOverChanged(true))
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))

        clock.advance(by: .seconds(3_600))
        await yieldMany()

        #expect(viewModel.state.banner == .deleted(note))
        #expect(clock.sleeperCount == 0)

        viewModel.send(.voiceOverChanged(false))
        await waitForBannerTimeout()
        clock.advance(by: .milliseconds(4_900))
        await yieldMany()

        #expect(viewModel.state.banner == .deleted(note))

        clock.advance(by: .milliseconds(100))
        await waitUntil { viewModel.state.banner == nil }

        #expect(viewModel.state.banner == nil)
    }

    @Test("given deleted banner counting down when VoiceOver turns on then the timeout is cancelled")
    func voiceOverOnWhileVisibleCancelsTimeout() async {
        let note = Note.fixture()
        let viewModel = makeViewModel()
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))
        await waitForBannerTimeout()

        viewModel.send(.voiceOverChanged(true))
        await waitUntil { clock.sleeperCount == 0 }
        clock.advance(by: .seconds(3_600))
        await yieldMany()

        #expect(viewModel.state.banner == .deleted(note))
    }

    @Test("given no banner when VoiceOver changes then no timeout is scheduled and no banner appears")
    func voiceOverWithoutBannerDoesNothing() async {
        let viewModel = makeViewModel()

        viewModel.send(.voiceOverChanged(true))
        viewModel.send(.voiceOverChanged(false))
        await yieldMany()

        #expect(viewModel.state.banner == nil)
        #expect(clock.sleeperCount == 0)
    }

    // MARK: - Acciones que dan la eliminación por definitiva (RF-20 a RF-23)

    @Test("given deleted banner visible when note tapped then hides banner, opens the note and undo restores nothing")
    func noteTappedHidesBanner() async {
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        let other = Note.fixture(title: "Otra")
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        await waitForBannerTimeout()

        viewModel.send(.noteTapped(other))

        #expect(viewModel.state.banner == nil)
        #expect(await effects.next() == .open(.note(other)))
        #expect(clock.sleeperCount == 0)

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 0)
    }

    @Test("given deleted banner visible when new note tapped then hides banner, opens new note and undo restores nothing")
    func newNoteTappedHidesBanner() async {
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        await waitForBannerTimeout()

        viewModel.send(.newNoteTapped)

        #expect(viewModel.state.banner == nil)
        #expect(await effects.next() == .open(.newNote))
        #expect(clock.sleeperCount == 0)

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 0)
    }

    @Test("given deleted banner visible when app moves to background then hides banner and undo restores nothing")
    func movedToBackgroundHidesBanner() async {
        let repository = FakeNoteRepository(finishesStreams: true)
        let viewModel = makeViewModel(repository: repository)
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        await waitForBannerTimeout()

        viewModel.send(.movedToBackground)

        #expect(viewModel.state.banner == nil)
        #expect(clock.sleeperCount == 0)

        viewModel.send(.undoTapped)
        await yieldMany()

        #expect(repository.saveCallCount == 0)
    }

    // MARK: - Eliminación repetida

    @Test("given banner of a deletion already hidden when the same deletion is sent again then banner is not shown")
    func sameDeletionDoesNotShowBannerTwice() async {
        let deletion = NoteDeletion(note: .fixture())
        let viewModel = makeViewModel()
        viewModel.send(.noteDeleted(deletion))
        await waitForBannerTimeout()
        clock.advance(by: NoteListViewModel.bannerDuration)
        await waitUntil { viewModel.state.banner == nil }

        viewModel.send(.noteDeleted(deletion))
        await yieldMany()

        #expect(viewModel.state.banner == nil)
        #expect(clock.sleeperCount == 0)
    }

    @Test("given banner of a deletion already hidden when a new deletion is sent then banner is shown again")
    func newDeletionShowsBannerAgain() async {
        let note = Note.fixture()
        let viewModel = makeViewModel()
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))
        viewModel.send(.movedToBackground)

        viewModel.send(.noteDeleted(NoteDeletion(note: note)))

        #expect(viewModel.state.banner == .deleted(note))
    }

    // MARK: - Estado vacío (RF-24, RF-26)

    @Test("given no notes stored when starting then state is empty")
    func noNotesShowsEmptyState() async {
        let viewModel = makeViewModel()

        await viewModel.start()

        #expect(viewModel.state.isEmpty)
    }

    @Test("given the only note was deleted when undo tapped then the note returns and state is no longer empty")
    func undoOnlyNoteLeavesEmptyState() async {
        let note = Note.fixture()
        let repository = FakeNoteRepository()
        let viewModel = makeViewModel(repository: repository)
        let observation = Task { await viewModel.start() }
        await waitUntil { viewModel.state.isEmpty }
        viewModel.send(.noteDeleted(NoteDeletion(note: note)))

        viewModel.send(.undoTapped)
        await waitUntil { viewModel.state.notes == [note] }

        #expect(viewModel.state.isEmpty == false)
        observation.cancel()
        await observation.value
    }

    // MARK: - Re-suscripción a efectos

    @Test("given effects resubscribed after a cancelled subscription when hiding intents sent then new stream receives effects and banner hides")
    func effectsSurviveResubscriptionWithBanner() async {
        let note = Note.fixture()
        let viewModel = makeViewModel()
        let firstStream = viewModel.effects()
        let firstConsumer = Task {
            var effects = firstStream.makeAsyncIterator()
            return await effects.next()
        }
        firstConsumer.cancel()
        #expect(await firstConsumer.value == nil)
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        viewModel.send(.noteTapped(note))

        #expect(viewModel.state.banner == nil)
        #expect(await effects.next() == .open(.note(note)))

        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        viewModel.send(.movedToBackground)
        viewModel.send(.noteDeleted(NoteDeletion(note: .fixture())))
        viewModel.send(.newNoteTapped)

        #expect(viewModel.state.banner == nil)
        #expect(await effects.next() == .open(.newNote))
    }
}
