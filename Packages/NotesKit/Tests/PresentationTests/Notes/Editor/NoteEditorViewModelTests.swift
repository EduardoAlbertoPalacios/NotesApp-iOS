import Common
import Domain
import Foundation
import Testing

@testable import Presentation

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct NoteEditorViewModelTests {
    private let clock = ManualClock()
    private let repository = FakeNoteRepository()
    /// Fecha que `SaveNoteUseCase` pone a lo que guarda; distinta de la apertura del editor (`Date.fixture`).
    private let savedAt = Date.fixture.addingTimeInterval(120)

    private func makeViewModel(_ destination: NotesDestination = .newNote) -> NoteEditorViewModel {
        NoteEditorViewModel(
            destination: destination,
            saveNote: SaveNoteUseCase(repository: repository, dateProvider: FixedDateProvider(savedAt)),
            clock: clock,
            dateProvider: FixedDateProvider(.fixture)
        )
    }

    /// Espera a que el guardado automático esté programado (su `sleep` registrado en el reloj).
    private func waitForScheduledSave() async {
        await waitUntil { clock.sleeperCount == 1 }
    }

    /// Cierra `stream` pidiendo uno nuevo y comprueba que no llegó ningún efecto.
    private func expectNoEffect(in stream: AsyncStream<NoteEditorEffect>, of viewModel: NoteEditorViewModel) async {
        _ = viewModel.effects()
        var effects = stream.makeAsyncIterator()
        #expect(await effects.next() == nil)
    }

    // MARK: - Guardado automático

    @Test("given a change when less than one second passes then does not save")
    func doesNotSaveBeforeOneSecond() async {
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()

        clock.advance(by: .milliseconds(999))
        await yieldMany()

        #expect(repository.saveCallCount == 0)
        #expect(clock.sleeperCount == 1)
        #expect(viewModel.state.saveStatus == .idle)
    }

    @Test("given a change when one second passes without changes then saves the note")
    func savesAfterOneSecond() async throws {
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("Compras"))
        viewModel.send(.textBlockChanged(index: 0, text: "Leche"))
        await waitForScheduledSave()

        clock.advance(by: .seconds(1))
        await waitUntil { repository.saveCallCount == 1 }

        let saved = try #require(repository.notes.first)
        #expect(repository.notes.count == 1)
        #expect(saved.title == "Compras")
        #expect(saved.blocks == [.text("Leche")])
    }

    @Test(
        "given several changes less than one second apart when one second passes then saves once with the last content")
    func debouncesConsecutiveChanges() async throws {
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("C"))
        await waitForScheduledSave()
        clock.advance(by: .milliseconds(600))
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()
        clock.advance(by: .milliseconds(600))
        viewModel.send(.textBlockChanged(index: 0, text: "Leche"))
        await waitForScheduledSave()
        clock.advance(by: .milliseconds(999))
        await yieldMany()
        #expect(repository.saveCallCount == 0)

        clock.advance(by: .milliseconds(1))
        await waitUntil { repository.saveCallCount == 1 }
        await yieldMany()

        let saved = try #require(repository.notes.first)
        #expect(repository.saveCallCount == 1)
        #expect(saved.title == "Compras")
        #expect(saved.blocks == [.text("Leche")])
    }

    @Test("given autosave when it finishes then status is saved and header shows the save date")
    func savedStatusAndHeaderDateAfterSave() async {
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()

        clock.advance(by: .seconds(1))
        await waitUntil { viewModel.state.saveStatus == .saved }

        #expect(viewModel.state.headerDate == savedAt)
        #expect(viewModel.state.title == "Compras")
    }

    // MARK: - Categoría y fijar

    @Test("given a category tapped when not selected then selects it and schedules a save")
    func categoryTappedSelectsCategory() async {
        let viewModel = makeViewModel(.note(.fixture(category: .work)))

        viewModel.send(.categoryTapped(.personal))

        #expect(viewModel.state.category == .personal)
        #expect(viewModel.state.saveStatus == .idle)
        await waitForScheduledSave()
    }

    @Test("given the selected category tapped then nothing changes and no save is scheduled")
    func tappingSelectedCategoryDoesNothing() async {
        let note = Note.fixture(category: .work)
        let viewModel = makeViewModel(.note(note))
        let initial = viewModel.state

        viewModel.send(.categoryTapped(.work))
        await yieldMany()

        #expect(viewModel.state == initial)
        #expect(clock.sleeperCount == 0)
    }

    @Test("given pin tapped twice then toggles pinned on and off")
    func pinTappedToggles() async {
        let viewModel = makeViewModel(.note(.fixture(isPinned: false)))

        viewModel.send(.pinTapped)
        let afterFirstTap = viewModel.state.isPinned
        viewModel.send(.pinTapped)

        #expect(afterFirstTap == true)
        #expect(viewModel.state.isPinned == false)
        await waitForScheduledSave()
    }

    // MARK: - Volver

    @Test("given pending changes when back tapped then saves without waiting and closes")
    func backWithPendingChangesSavesAndCloses() async throws {
        let note = Note.fixture(title: "Compras")
        let viewModel = makeViewModel(.note(note))
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.titleChanged("Compras del sábado"))

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
        let saved = try #require(repository.notes.first)
        #expect(repository.saveCallCount == 1)
        #expect(saved.id == note.id)
        #expect(saved.title == "Compras del sábado")
        #expect(saved.updatedAt == savedAt)
    }

    @Test("given existing note without changes when back tapped then closes without saving")
    func backWithoutChangesClosesWithoutSaving() async {
        let viewModel = makeViewModel(.note(.fixture()))
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
        #expect(repository.saveCallCount == 0)
        #expect(repository.notes.isEmpty)
    }

    @Test("given edits reverted to the saved content when back tapped then closes without saving")
    func backWithRevertedChangesClosesWithoutSaving() async {
        let note = Note.fixture(title: "Compras", blocks: [.task(NoteTask(text: "Leche"))])
        let viewModel = makeViewModel(.note(note))
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.titleChanged("Otra cosa"))
        viewModel.send(.titleChanged("Compras"))

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
        #expect(repository.saveCallCount == 0)
        #expect(repository.nextSequenceCallCount == 0)
    }

    @Test("given empty new note when back tapped then closes without creating a note")
    func backOnEmptyNewNoteClosesWithoutSaving() async {
        let viewModel = makeViewModel()
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
        #expect(repository.saveCallCount == 0)
        #expect(repository.nextSequenceCallCount == 0)
    }

    @Test("given new note saved and then emptied when back tapped then deletes it and closes")
    func backOnEmptiedNewNoteDeletesIt() async throws {
        let viewModel = makeViewModel()
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()
        clock.advance(by: .seconds(1))
        await waitUntil { viewModel.state.saveStatus == .saved }
        let saved = try #require(repository.notes.first)
        viewModel.send(.titleChanged(""))

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
        #expect(repository.deletedIDs == [saved.id])
        #expect(repository.notes.isEmpty)
    }

    // MARK: - Errores al guardar

    @Test("given save fails when autosaving then status is failed and the text stays in the editor")
    func failedSaveKeepsText() async {
        repository.failSaves(with: .storageUnavailable)
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()

        clock.advance(by: .seconds(1))
        await waitUntil { viewModel.state.saveStatus == .failed }

        #expect(viewModel.state.title == "Compras")
        #expect(repository.notes.isEmpty)
    }

    @Test("given a failed save when a later change saves successfully then status becomes saved")
    func laterChangeRetriesAfterFailure() async throws {
        repository.failSaves(with: .storageUnavailable)
        let viewModel = makeViewModel()
        viewModel.send(.titleChanged("Compras"))
        await waitForScheduledSave()
        clock.advance(by: .seconds(1))
        await waitUntil { viewModel.state.saveStatus == .failed }
        repository.failSaves(with: nil)

        viewModel.send(.textBlockChanged(index: 0, text: "Leche"))
        await waitForScheduledSave()
        clock.advance(by: .seconds(1))
        await waitUntil { viewModel.state.saveStatus == .saved }

        let saved = try #require(repository.notes.first)
        #expect(saved.title == "Compras")
        #expect(saved.blocks == [.text("Leche")])
    }

    @Test("given save fails when back tapped then presents discard dialog and does not close")
    func backWithFailedSavePresentsDialog() async {
        repository.failSaves(with: .storageUnavailable)
        let viewModel = makeViewModel(.note(.fixture()))
        let stream = viewModel.effects()
        viewModel.send(.titleChanged("Compras"))

        viewModel.send(.backTapped)
        await waitUntil { viewModel.state.isDiscardDialogPresented }

        #expect(viewModel.state.saveStatus == .failed)
        await expectNoEffect(in: stream, of: viewModel)
    }

    @Test("given discard dialog when discard confirmed then closes and dismisses the dialog")
    func discardConfirmedCloses() async {
        repository.failSaves(with: .storageUnavailable)
        let viewModel = makeViewModel(.note(.fixture()))
        var effects = viewModel.effects().makeAsyncIterator()
        viewModel.send(.titleChanged("Compras"))
        viewModel.send(.backTapped)
        await waitUntil { viewModel.state.isDiscardDialogPresented }

        viewModel.send(.discardConfirmed)

        #expect(await effects.next() == .close)
        #expect(viewModel.state.isDiscardDialogPresented == false)
    }

    @Test("given discard dialog when keep editing tapped then dismisses the dialog, keeps the text and does not close")
    func keepEditingDismissesDialog() async {
        repository.failSaves(with: .storageUnavailable)
        let viewModel = makeViewModel(.note(.fixture()))
        let stream = viewModel.effects()
        viewModel.send(.titleChanged("Compras"))
        viewModel.send(.backTapped)
        await waitUntil { viewModel.state.isDiscardDialogPresented }

        viewModel.send(.keepEditingTapped)

        #expect(viewModel.state.isDiscardDialogPresented == false)
        #expect(viewModel.state.title == "Compras")
        await expectNoEffect(in: stream, of: viewModel)
    }

    // MARK: - Efectos

    @Test("given first effects subscription cancelled when resubscribing then new stream receives close")
    func effectsSurviveResubscription() async {
        let viewModel = makeViewModel()
        let first = viewModel.effects()
        let consumer = Task { for await _ in first {} }
        consumer.cancel()
        await consumer.value
        var effects = viewModel.effects().makeAsyncIterator()

        viewModel.send(.backTapped)

        #expect(await effects.next() == .close)
    }
}
