import Common
import Foundation
import Testing

@testable import Domain

struct DeleteNoteUseCaseTests {
    private let now = Date.fixture.addingTimeInterval(3_600)

    private func makeSut(repository: FakeNoteRepository = FakeNoteRepository()) -> DeleteNoteUseCase {
        DeleteNoteUseCase(repository: repository, dateProvider: FixedDateProvider(now))
    }

    // MARK: - Vacía

    @Test("given new empty draft never saved when deleting then discards without touching the repository")
    func newEmptyUnsavedDiscards() async throws {
        let repository = FakeNoteRepository()
        let draft = NoteDraft(isNew: true, title: " \n ", blocks: [.text("  ")])

        let result = try await makeSut(repository: repository)(draft, lastSaved: nil)

        #expect(result == .discarded)
        #expect(repository.deletedIDs.isEmpty)
        #expect(repository.savedBatches.isEmpty)
        #expect(repository.nextSequenceCallCount == 0)
    }

    @Test("given new empty draft already saved when deleting then deletes it and discards")
    func newEmptySavedDeletesAndDiscards() async throws {
        let saved = Note.fixture(title: "Compras")
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(id: saved.id, isNew: true)

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .discarded)
        #expect(repository.deletedIDs == [saved.id])
        #expect(repository.savedBatches.isEmpty)
    }

    @Test("given existing note emptied when deleting then deletes it and returns its last saved version")
    func existingEmptiedReturnsLastSaved() async throws {
        let saved = Note.fixture(
            title: "Compras", blocks: [.text("Leche")], color: .pink, category: .personal,
            isPinned: true, sequence: 7)
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(id: saved.id, isNew: false, title: "  ", blocks: [.text("\n")])

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .deleted(saved))
        #expect(repository.deletedIDs == [saved.id])
        #expect(repository.savedBatches.isEmpty)
    }

    // MARK: - Con contenido

    @Test(
        "given draft with unsaved changes and last saved version when deleting then deletes it and returns draft content with saved color, date and order"
    )
    func contentWithLastSavedReturnsMergedCopy() async throws {
        let saved = Note.fixture(
            title: "Compras", blocks: [.text("Leche")], color: .lavender, category: nil,
            isPinned: false, updatedAt: .fixture, sequence: 4)
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(
            id: saved.id, isNew: false, title: "Compras del sábado",
            blocks: [.text("Leche y pan")], category: .work, isPinned: true)

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        let expected = Note(
            id: saved.id, title: "Compras del sábado", blocks: [.text("Leche y pan")],
            color: .lavender, category: .work, isPinned: true, updatedAt: .fixture, sequence: 4)
        #expect(result == .deleted(expected))
        #expect(repository.deletedIDs == [saved.id])
        #expect(repository.nextSequenceCallCount == 0)
    }

    @Test(
        "given new draft with content never saved when deleting then returns copy as first save without deleting"
    )
    func contentNeverSavedReturnsFirstSaveCopy() async throws {
        let repository = FakeNoteRepository(nextSequence: 12)
        let draft = NoteDraft(
            isNew: true, title: "Ideas", blocks: [.text("Viaje")], category: .personal,
            isPinned: true)

        let result = try await makeSut(repository: repository)(draft, lastSaved: nil)

        let expected = Note(
            id: draft.id, title: "Ideas", blocks: [.text("Viaje")], color: .aqua,
            category: .personal, isPinned: true, updatedAt: now, sequence: 12)
        #expect(result == .deleted(expected))
        #expect(repository.deletedIDs.isEmpty)
        #expect(repository.savedBatches.isEmpty)
        #expect(repository.nextSequenceCallCount == 1)
    }

    // MARK: - Limpieza

    @Test(
        "given title with outer whitespace and blank text blocks when deleting then copy has trimmed title, no blank text and keeps tasks"
    )
    func cleansDraftInCopy() async throws {
        let saved = Note.fixture(title: "Tareas")
        let repository = FakeNoteRepository(notes: [saved])
        let done = NoteTask(text: "Pagar luz", isDone: true)
        let pending = NoteTask(text: "", isDone: false)
        let draft = NoteDraft(
            id: saved.id, isNew: false, title: " \n Tareas  de hoy \t\n",
            blocks: [.text("  "), .task(done), .text("Nota"), .task(pending), .text("\n")])

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        let note = try #require(result.deletedNote)
        #expect(note.title == "Tareas  de hoy")
        #expect(note.blocks == [.task(done), .text("Nota"), .task(pending)])
    }

    @Test("given only tasks and blank title when deleting then is not treated as empty")
    func tasksOnlyIsContent() async throws {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved])
        let task = NoteTask(text: "Llamar", isDone: false)
        let draft = NoteDraft(id: saved.id, isNew: true, title: "  ", blocks: [.task(task)])

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        let note = try #require(result.deletedNote)
        #expect(note.title == "")
        #expect(note.blocks == [.task(task)])
        #expect(repository.deletedIDs == [saved.id])
    }

    // MARK: - Errores

    @Test("given delete fails when deleting a saved note with content then throws the same AppError")
    func deleteFailureWithContent() async {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved], deleteFailure: .storageUnavailable)

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(repository: repository)(NoteDraft(editing: saved), lastSaved: saved)
        }
    }

    @Test("given delete fails when deleting an emptied existing note then throws the same AppError")
    func deleteFailureWhenEmptied() async {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved], deleteFailure: .corruptedData)

        await #expect(throws: AppError.corruptedData) {
            try await makeSut(repository: repository)(
                NoteDraft(id: saved.id, isNew: false), lastSaved: saved)
        }
    }

    @Test("given delete fails when discarding a saved new empty note then throws the same AppError")
    func deleteFailureWhenDiscarding() async {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved], deleteFailure: .storageUnavailable)

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(repository: repository)(
                NoteDraft(id: saved.id, isNew: true), lastSaved: saved)
        }
    }

    @Test("given next sequence fails when deleting a never saved note then throws the same AppError")
    func nextSequenceFailure() async {
        let repository = FakeNoteRepository(sequenceFailure: .corruptedData)

        await #expect(throws: AppError.corruptedData) {
            try await makeSut(repository: repository)(
                NoteDraft(isNew: true, title: "Ideas"), lastSaved: nil)
        }
    }

    @Test("given delete fails when deleting then the error is statically typed as AppError")
    func errorIsTypedAppError() async {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved], deleteFailure: .storageUnavailable)
        var caught: AppError?

        do {
            _ = try await makeSut(repository: repository)(NoteDraft(editing: saved), lastSaved: saved)
        } catch {
            caught = error
        }

        #expect(caught == .storageUnavailable)
    }
}

extension NoteDeletionResult {
    fileprivate var deletedNote: Note? {
        guard case .deleted(let note) = self else { return nil }
        return note
    }
}
