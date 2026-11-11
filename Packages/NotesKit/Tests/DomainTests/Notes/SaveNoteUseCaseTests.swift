import Common
import Foundation
import Testing

@testable import Domain

struct SaveNoteUseCaseTests {
    private let now = Date.fixture.addingTimeInterval(3_600)

    private func makeSut(repository: FakeNoteRepository = FakeNoteRepository()) -> SaveNoteUseCase {
        SaveNoteUseCase(repository: repository, dateProvider: FixedDateProvider(now))
    }

    // MARK: - Vacía

    @Test(
        "given new empty draft never saved when saving then skips without touching the repository")
    func newEmptyUnsavedSkips() async throws {
        let repository = FakeNoteRepository()

        let result = try await makeSut(repository: repository)(
            NoteDraft(isNew: true), lastSaved: nil)

        #expect(result == .skipped)
        #expect(repository.savedBatches.isEmpty)
        #expect(repository.deletedIDs.isEmpty)
        #expect(repository.nextSequenceCallCount == 0)
    }

    @Test("given new note already saved when emptied then deletes it and returns deleted")
    func newSavedEmptiedDeletes() async throws {
        let saved = Note.fixture(title: "Compras")
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(id: saved.id, isNew: true)

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .deleted)
        #expect(repository.deletedIDs == [saved.id])
        #expect(repository.savedBatches.isEmpty)
    }

    @Test("given existing note when emptied then skips without saving or deleting")
    func existingEmptiedSkips() async throws {
        let saved = Note.fixture(title: "Compras")
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(id: saved.id, isNew: false)

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .skipped)
        #expect(repository.savedBatches.isEmpty)
        #expect(repository.deletedIDs.isEmpty)
    }

    @Test(
        "given title and text blocks with only spaces and newlines when saving new draft then counts as empty"
    )
    func whitespaceOnlyCountsAsEmpty() async throws {
        let repository = FakeNoteRepository()
        let draft = NoteDraft(
            isNew: true, title: "  \n\t ", blocks: [.text(" "), .text("\n\n"), .text("")])

        let result = try await makeSut(repository: repository)(draft, lastSaved: nil)

        #expect(result == .skipped)
        #expect(repository.savedBatches.isEmpty)
    }

    @Test("given saved new note emptied to whitespace when saving then deletes it")
    func whitespaceOnlyDeletesSavedNewNote() async throws {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved])
        let draft = NoteDraft(id: saved.id, isNew: true, title: " \n ", blocks: [.text("  \n")])

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .deleted)
        #expect(repository.deletedIDs == [saved.id])
    }

    // MARK: - Sin cambios

    @Test("given draft equal to last saved when saving then skips and keeps updatedAt")
    func unchangedSkips() async throws {
        let saved = Note.fixture(title: "Compras", category: .personal, isPinned: true)
        let repository = FakeNoteRepository(notes: [saved])

        let result = try await makeSut(repository: repository)(
            NoteDraft(editing: saved), lastSaved: saved)

        #expect(result == .skipped)
        #expect(repository.savedBatches.isEmpty)
    }

    @Test("given draft equal to last saved plus trailing empty text block when saving then skips")
    func unchangedWithTrailingEmptyBlockSkips() async throws {
        let saved = Note.fixture(title: "Compras", blocks: [.text("Leche")])
        let repository = FakeNoteRepository(notes: [saved])
        var draft = NoteDraft(editing: saved)
        draft.blocks.append(.text(""))

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        #expect(result == .skipped)
        #expect(repository.savedBatches.isEmpty)
    }

    // MARK: - Cambios

    @Test(
        "given one field changed from last saved when saving then saves with updatedAt now",
        arguments: [
            "title", "content", "category", "pinned",
        ]
    )
    func changedFieldSaves(field: String) async throws {
        let saved = Note.fixture(
            title: "Compras", blocks: [.text("Leche")], category: .work, isPinned: false)
        let repository = FakeNoteRepository(notes: [saved])
        var draft = NoteDraft(editing: saved)
        switch field {
        case "title": draft.title = "Súper"
        case "content": draft.blocks = [.text("Pan")]
        case "category": draft.category = nil
        default: draft.isPinned = true
        }

        let result = try await makeSut(repository: repository)(draft, lastSaved: saved)

        let expected = Note(
            id: saved.id,
            title: draft.title,
            blocks: draft.blocks,
            color: saved.color,
            category: draft.category,
            isPinned: draft.isPinned,
            updatedAt: now,
            sequence: saved.sequence
        )
        #expect(result == .saved(expected))
        #expect(repository.savedBatches == [[expected]])
    }

    // MARK: - Primera vez y siguientes

    @Test("given never saved draft when saving then uses aqua color and the next sequence")
    func firstSaveUsesAquaAndNextSequence() async throws {
        let repository = FakeNoteRepository(nextSequence: 7)
        let draft = NoteDraft(isNew: true, title: "Ideas")

        let result = try await makeSut(repository: repository)(draft, lastSaved: nil)

        let note = try #require(repository.savedBatches.first?.first)
        #expect(result == .saved(note))
        #expect(note.id == draft.id)
        #expect(note.color == .aqua)
        #expect(note.sequence == 7)
        #expect(note.updatedAt == now)
        #expect(repository.nextSequenceCallCount == 1)
    }

    @Test(
        "given previously saved note when saving changes then keeps its color and sequence without asking for one"
    )
    func laterSaveKeepsColorAndSequence() async throws {
        let saved = Note.fixture(title: "Ideas", color: .lavender, sequence: 3)
        let repository = FakeNoteRepository(notes: [saved], nextSequence: 99)
        var draft = NoteDraft(id: saved.id, isNew: true, title: saved.title, blocks: saved.blocks)
        draft.title = "Ideas nuevas"

        _ = try await makeSut(repository: repository)(draft, lastSaved: saved)

        let note = try #require(repository.savedBatches.first?.first)
        #expect(note.color == .lavender)
        #expect(note.sequence == 3)
        #expect(repository.nextSequenceCallCount == 0)
    }

    // MARK: - Título y bloques

    @Test("given empty title with content when saving then saves an empty title")
    func emptyTitleWithContentSaves() async throws {
        let repository = FakeNoteRepository()
        let draft = NoteDraft(isNew: true, title: "  ", blocks: [.text("Leche")])

        _ = try await makeSut(repository: repository)(draft, lastSaved: nil)

        let note = try #require(repository.savedBatches.first?.first)
        #expect(note.title == "")
        #expect(note.blocks == [.text("Leche")])
    }

    @Test("given title surrounded by spaces and newlines when saving then saves it trimmed")
    func titleIsTrimmed() async throws {
        let repository = FakeNoteRepository()
        let draft = NoteDraft(isNew: true, title: " \n Compras \t\n")

        _ = try await makeSut(repository: repository)(draft, lastSaved: nil)

        let note = try #require(repository.savedBatches.first?.first)
        #expect(note.title == "Compras")
    }

    @Test(
        "given blank text blocks among tasks when saving then drops blank text and keeps tasks as is and in order"
    )
    func blankTextDroppedTasksKept() async throws {
        let repository = FakeNoteRepository()
        let pending = NoteTask(text: "Leche")
        let blankTask = NoteTask(text: "  ", isDone: true)
        let draft = NoteDraft(
            isNew: true,
            title: "Compras",
            blocks: [
                .text(" "), .task(pending), .text("Notas"), .text("\n"), .task(blankTask),
                .text(""),
            ]
        )

        _ = try await makeSut(repository: repository)(draft, lastSaved: nil)

        let note = try #require(repository.savedBatches.first?.first)
        #expect(note.blocks == [.task(pending), .text("Notas"), .task(blankTask)])
    }

    // MARK: - Errores

    @Test("given save fails when saving changes then throws the same AppError")
    func saveFailurePropagates() async {
        let repository = FakeNoteRepository(saveFailure: .storageUnavailable)
        let draft = NoteDraft(isNew: true, title: "Compras")

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(repository: repository)(draft, lastSaved: nil)
        }
    }

    @Test("given delete fails when emptying a saved new note then throws the same AppError")
    func deleteFailurePropagates() async {
        let saved = Note.fixture()
        let repository = FakeNoteRepository(notes: [saved], deleteFailure: .corruptedData)
        let draft = NoteDraft(id: saved.id, isNew: true)

        await #expect(throws: AppError.corruptedData) {
            try await makeSut(repository: repository)(draft, lastSaved: saved)
        }
    }

    @Test(
        "given next sequence fails when saving for the first time then throws the same AppError and saves nothing"
    )
    func nextSequenceFailurePropagates() async {
        let repository = FakeNoteRepository(sequenceFailure: .storageUnavailable)
        let draft = NoteDraft(isNew: true, title: "Compras")

        await #expect(throws: AppError.storageUnavailable) {
            try await makeSut(repository: repository)(draft, lastSaved: nil)
        }

        #expect(repository.savedBatches.isEmpty)
    }
}
